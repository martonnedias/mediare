from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from routers.auth import verify_token
from database import get_db
from models import EventLog, FamilyUnit, Agreement
from datetime import datetime, timezone
from ai_utils import gemini_client

router = APIRouter()

class AgreementRequest(BaseModel):
    conflict_context: str
    child_name: str
    family_unit_id: int

@router.post("/agreements/suggest")
def suggest_agreement(request: AgreementRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    family = db.query(FamilyUnit).filter(FamilyUnit.id == request.family_unit_id).first()
    mode = family.mode if family else "Colaborativo"
    
    if mode.lower() == "unilateral":
        role_desc = "Você é um assistente jurídico registrando uma decisão unilateral de um genitor."
        goal_desc = "A sugestão deve focar em como comunicar a decisão de forma clara e não agressiva, registrando os motivos."
    else:
        role_desc = "Você é um mediador familiar especializado em gestão de conflitos de coparentalidade."
        goal_desc = "Sugira uma resolução justa, neutra e focada no bem-estar da criança, buscando o consenso entre as partes."

    prompt = f"""
    {role_desc}
    Contexto: {request.conflict_context}
    Criança envolvida: {request.child_name}
    
    {goal_desc}
    O tom deve ser pacificador e a sugestão deve ser prática e acionável.
    Formate como um pequeno parágrafo de sugestão e 3 pontos de ação.
    """
    
    try:
        suggestion = gemini_client.generate_content(prompt)
        
        if not suggestion:
            # Mock implementation for internal dev or if AI fails
            suggestion = f"Sugestão Global: Priorizem a rotina de {request.child_name}. \n\nAções:\n1. Estabelecer horários fixos.\n2. Comunicar mudanças com 24h de antecedência.\n3. Usar o calendário compartilhado para registros."
            
        # Log this generation as an event
        new_event = EventLog(
            event_type='ai_agreement_suggested',
            event_data=str({'conflict': request.conflict_context, 'suggestion': suggestion}),
            family_unit_id=request.family_unit_id,
            created_at=datetime.now(timezone.utc)
        )
        db.add(new_event)
        db.commit()
        
        return {"suggestion": suggestion, "status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao processar IA: {str(e)}")

class CreateAgreementRequest(BaseModel):
    title: str
    content: str
    status: str = "draft"

@router.post("/agreements")
def create_agreement(request: CreateAgreementRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    agreement = Agreement(
        title=request.title,
        content=request.content,
        status=request.status,
        family_unit_id=user.family_unit_id,
        created_at=datetime.now(timezone.utc)
    )
    db.add(agreement)
    db.commit()
    db.refresh(agreement)
    return {"message": "Agreement created successfully", "agreement_id": agreement.id}

@router.get("/agreements")
def list_agreements(db: Session = Depends(get_db), user = Depends(verify_token)):
    agreements = db.query(Agreement).filter(Agreement.family_unit_id == user.family_unit_id).all()
    return {"agreements": agreements}

@router.put("/agreements/{agreement_id}")
def update_agreement(agreement_id: int, request: CreateAgreementRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    agreement = db.query(Agreement).filter(Agreement.id == agreement_id, Agreement.family_unit_id == user.family_unit_id).first()
    if not agreement:
        raise HTTPException(status_code=404, detail="Agreement not found")
    
    # Regra: Se cumprido, não pode mais alterar (exceto suporte - simulado por flag no user se existisse, aqui bloqueamos geral conforme pedido)
    if agreement.status == "fulfilled":
        raise HTTPException(status_code=403, detail="Acordos cumpridos não podem mais ser alterados. Entre em contato com o suporte.")

    agreement.title = request.title
    agreement.content = request.content
    
    # Se o novo status for fulfilled, registramos a data
    if request.status == "fulfilled" and agreement.status != "fulfilled":
        agreement.fulfilled_at = datetime.now(timezone.utc)
    
    agreement.status = request.status
    db.commit()
    return {"message": "Agreement updated successfully"}

@router.delete("/agreements/{agreement_id}")
def delete_agreement(agreement_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    agreement = db.query(Agreement).filter(Agreement.id == agreement_id, Agreement.family_unit_id == user.family_unit_id).first()
    if not agreement:
        raise HTTPException(status_code=404, detail="Agreement not found")

    if agreement.status == "fulfilled":
        raise HTTPException(status_code=403, detail="Acordos cumpridos não podem ser excluídos.")

    db.delete(agreement)
    db.commit()
    return {"message": "Agreement deleted successfully"}
