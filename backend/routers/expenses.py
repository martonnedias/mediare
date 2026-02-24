from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from hashlib import sha256
from datetime import datetime, timezone
from routers.auth import verify_token, check_family_access
from database import get_db
from models import Expense, ExpenseShare
import boto3
import os
import os
from typing import Optional
from pydantic import BaseModel

router = APIRouter()

# S3 Client Configuration
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME", "mediare-documents")
s3_client = boto3.client('s3') if 'AWS_ACCESS_KEY_ID' in os.environ else None
UPLOAD_DIR = os.path.join(os.getcwd(), "expenses")

@router.post("/expenses/analyze-receipt")
async def analyze_receipt(file: UploadFile = File(...), user = Depends(verify_token)):
    """Analisa uma foto de recibo e extrai dados via IA."""
    from ai_utils import gemini_client
    
    content = await file.read()
    
    prompt = """
    Você é um assistente financeiro especializado em ler recibos e notas fiscais.
    Analise a imagem anexada e extraia os dados necessários para o cadastro de uma despesa.
    Tente identificar: Descrição do item/serviço, Valor Total (apenas o número) e Data.
    
    Retorne APENAS um JSON (sem markdown) com os campos:
    - description: str (ex: Farmácia, Escola, Uniforme)
    - amount: float (valor numérico)
    - date: str (formato YYYY-MM-DD se encontrado)
    - category: str (Educação, Saúde, Lazer ou Outros)
    """
    
    analysis = gemini_client.analyze_image(prompt, content, mime_type=file.content_type)
    
    if not analysis:
        raise HTTPException(status_code=500, detail="IA falhou ao processar a imagem. Tente uma foto mais nítida.")
        
    return analysis

@router.get("/expenses/categories")
def get_expense_categories():
    return {
        "categories": [
            "Educação", "Saúde", "Alimentação", "Vestuário", 
            "Lazer", "Transporte", "Moradia", "Outros"
        ]
    }

@router.post("/expenses")
def create_expense(
    description: str = Form(...),
    amount: float = Form(...),
    child_id: int = Form(...),
    family_unit_id: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user = Depends(verify_token)
):
    # Security Check
    check_family_access(db, user.id, family_unit_id)
    
    file_content = file.file.read()
    file_hash = sha256(file_content).hexdigest()
    filename = f"{datetime.now().strftime('%Y%m%d%H%M%S')}_{file.filename}"
    
    if s3_client:
        try:
            s3_client.put_object(
                Bucket=S3_BUCKET_NAME,
                Key=f"expenses/{filename}",
                Body=file_content,
                ContentType=file.content_type
            )
            file_url = f"s3://{S3_BUCKET_NAME}/expenses/{filename}"
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"S3 Upload failed: {str(e)}")
    else:
        # Fallback local storage
        os.makedirs(UPLOAD_DIR, exist_ok=True)
        file_path = os.path.join(UPLOAD_DIR, filename)
        with open(file_path, "wb") as buffer:
            buffer.write(file_content)
        file_url = f"/expenses/{filename}"

    # Create expense
    expense = Expense(
        description=description,
        amount=amount,
        attachment_url=file_url,
        attachment_hash_sha256=file_hash,
        family_unit_id=family_unit_id,
        child_id=child_id,
        created_at=datetime.now(timezone.utc),
        status="Aprovado"
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)

    # Create automatic 50/50 share
    share = ExpenseShare(
        expense_id=expense.id,
        user_id=user.id,
        share_percentage=50.0,
        amount=amount / 2
    )
    db.add(share)
    db.commit()

    return {"message": "Expense created successfully", "expense_id": expense.id, "file_url": file_url}

from fastapi.responses import FileResponse

@router.get("/attachments/expenses/{expense_id}")
def get_expense_attachment(expense_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    expense = db.query(Expense).filter(Expense.id == expense_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
        
    # Security Check
    check_family_access(db, user.id, expense.family_unit_id)
    
    url = expense.attachment_url
    if url.startswith("s3://"):
        # Generate presigned URL
        if not s3_client:
             raise HTTPException(status_code=500, detail="S3 configuration missing for this file")
        bucket = url.split("/")[2]
        key = "/".join(url.split("/")[3:])
        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': bucket, 'Key': key},
            ExpiresIn=3600
        )
        return {"url": presigned_url, "type": "s3_presigned"}
    else:
        # Local file
        local_name = os.path.basename(url)
        local_path = os.path.join(UPLOAD_DIR, local_name)
            
        if os.path.exists(local_path):
            return FileResponse(local_path)
        else:
            raise HTTPException(status_code=404, detail=f"File not found on server: {local_path}")

@router.delete("/expenses/{expense_id}")
def delete_expense(expense_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    expense = db.query(Expense).filter(Expense.id == expense_id, Expense.family_unit_id == user.family_unit_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    
    # Optional: Delete file from S3/Local if needed, but for now we keep it for audit or manual cleanup
    
    db.delete(expense)
    db.commit()
    return {"message": "Expense deleted successfully"}

class ExpenseUpdateRequest(BaseModel):
    description: Optional[str] = None
    amount: Optional[float] = None
    status: Optional[str] = None

@router.put("/expenses/{expense_id}")
def update_expense(expense_id: int, request: ExpenseUpdateRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    expense = db.query(Expense).filter(Expense.id == expense_id, Expense.family_unit_id == user.family_unit_id).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    
    if request.description is not None:
        expense.description = request.description
    if request.amount is not None:
        expense.amount = request.amount
        # Note: Recalculating shares would be complex here, assuming 50/50 split remains or requires manual adjustment
    if request.status is not None:
        expense.status = request.status
        
    db.commit()
    return {"message": "Expense updated successfully"}

@router.get("/expenses")
def list_expenses(
    family_unit_id: int, 
    child_id: Optional[int] = None, 
    start_date: Optional[str] = None, 
    end_date: Optional[str] = None, 
    db: Session = Depends(get_db), 
    user = Depends(verify_token)
):
    # Security Check
    check_family_access(db, user.id, family_unit_id)
    
    query = db.query(Expense).filter(Expense.family_unit_id == family_unit_id)
    if child_id:
        query = query.filter(Expense.child_id == child_id)
    if start_date and end_date:
        query = query.filter(Expense.created_at >= start_date, Expense.created_at <= end_date)
    expenses = query.all()
    return {"expenses": expenses}