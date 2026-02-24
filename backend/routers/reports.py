from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from .auth import verify_token, check_family_access
from database import get_db
from models import EventLog, Report
from datetime import datetime, timezone
from hashlib import sha256
import os
try:
    from reportlab.pdfgen import canvas
except ImportError:
    canvas = None
    print("WARNING: reportlab not installed. PDF generation disabled.")

router = APIRouter()

class ReportRequest(BaseModel):
    name: str
    filters: dict

@router.post("/reports")
def generate_report(request: ReportRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    if user.family_unit_id:
        check_family_access(db, user.id, user.family_unit_id)
    
    # Ensure reports directory exists
    if not canvas:
        raise HTTPException(status_code=503, detail="PDF generation service unavailable (reportlab missing)")
    os.makedirs("reports", exist_ok=True)
    
    # Fetch context
    from models import Expense
    
    events = []
    if request.filters.get("include_events"):
        events = db.query(EventLog).filter(EventLog.family_unit_id == user.family_unit_id).order_by(EventLog.created_at.desc()).limit(100).all()
    
    expenses = []
    if request.filters.get("include_expenses"):
        expenses = db.query(Expense).filter(Expense.family_unit_id == user.family_unit_id).order_by(Expense.created_at.desc()).limit(50).all()

    # IA Executive Summary
    ai_summary = ""
    try:
        from ai_utils import gemini_client
        context_text = f"Análise de convivência para a família {user.full_name}.\n"
        context_text += "Eventos recentes:\n" + "\n".join([f"- {e.event_type}: {e.event_data[:100]}" for e in events])
        context_text += "\nDespesas recentes:\n" + "\n".join([f"- {ex.description}: R$ {ex.amount}" for ex in expenses])
        
        prompt = f"""
        Você é um mediador de conflitos familiar de alto nível.
        Analise os seguintes dados de convivência e finanças e escreva um "Sumário Executivo do Mediador" de no máximo 5 linhas.
        O tom deve ser profissional, neutro e focado em destacar a colaboração ou pontos que precisam de atenção diplomática.
        Este sumário será lido por um Juiz ou Mediador.
        
        DADOS:
        {context_text}
        """
        ai_summary = gemini_client.generate_content(prompt)
    except Exception as e:
        ai_summary = "Sumário IA indisponível no momento."

    # Generate PDF
    file_name = f"relatorio_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
    pdf_path = f"reports/{file_name}"
    
    c = canvas.Canvas(pdf_path)
    c.setFont("Helvetica-Bold", 16)
    c.drawString(40, 800, "MEDIARE - Relatório Auditado de Compliance Familiar")
    c.setFont("Helvetica", 10)
    c.drawString(40, 780, f"Nome do Documento: {request.name}")
    c.drawString(40, 765, f"Data de Geração: {datetime.now().strftime('%d/%m/%Y %H:%M:%S')}")
    c.drawString(40, 750, f"Gerado por: {user.full_name}")
    c.line(40, 745, 550, 745)

    y = 730
    if ai_summary:
        c.setFont("Helvetica-BoldOblique", 11)
        c.setFillColorRGB(0.1, 0.4, 0.8) # Blueish for AI section
        c.drawString(40, y, "PARECER AUTOMÁTICO DO MEDIADOR (IA):")
        y -= 15
        c.setFont("Helvetica-Oblique", 10)
        c.setFillColorRGB(0, 0, 0)
        
        # Simple text wrap for summary
        summary_lines = [ai_summary[i:i+95] for i in range(0, len(ai_summary), 95)]
        for line in summary_lines:
             c.drawString(45, y, line)
             y -= 12
        y -= 10

    c.setFont("Helvetica-Bold", 12)
    c.drawString(40, y, "Atividades e Registros:")
    y -= 25
    
    c.setFont("Helvetica", 9)
    if not events and not expenses:
        c.drawString(40, y, "Nenhum dado selecionado ou encontrado no período.")
    
    # Render Events
    if events:
        c.setFont("Helvetica-Bold", 10)
        c.drawString(40, y, "EVENTOS DE CONVIVÊNCIA E TROCAS")
        y -= 15
        c.setFont("Helvetica", 8)
        for event in events:
            c.drawString(40, y, f"[{event.created_at.strftime('%d/%m/%Y %H:%M')}] {event.event_type.upper()}: {event.event_data[:120]}")
            y -= 12
            if y < 80:
                c.showPage()
                y = 800
                c.setFont("Helvetica", 8)

    # Render Expenses
    if expenses:
        if y < 150:
            c.showPage()
            y = 800
        y -= 20
        c.setFont("Helvetica-Bold", 10)
        c.drawString(40, y, "DESPESAS E MOVIMENTAÇÕES FINANCEIRAS")
        y -= 15
        c.setFont("Helvetica", 8)
        for exp in expenses:
            status = exp.status
            c.drawString(40, y, f"[{exp.created_at.strftime('%d/%m/%Y')}] {exp.description}: R$ {exp.amount:.2f} ({status})")
            y -= 12
            if y < 80:
                c.showPage()
                y = 800
                c.setFont("Helvetica", 8)

    # Temporary save to calculate hash
    c.save()

    with open(pdf_path, "rb") as pdf_file:
        pdf_content = pdf_file.read()
        pdf_hash = sha256(pdf_content).hexdigest()

    # Re-save with hash footer (simplified for MVP: we just record it in DB)
    # The real approach would be signing the PDF bytes after generation
    
    # Save report to database
    report = Report(
        name=request.name,
        filters=str(request.filters),
        pdf_url=f"/reports/{file_name}", # Local relative path for front serving
        hash_sha256=pdf_hash,
        created_at=datetime.now(timezone.utc),
        family_unit_id=user.family_unit_id
    )
    db.add(report)
    db.commit()
    db.refresh(report)

    return {"message": "Report generated successfully", "report_id": report.id, "hash": pdf_hash, "url": report.pdf_url}

@router.get("/reports")
def list_reports(db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    if user.family_unit_id:
        check_family_access(db, user.id, user.family_unit_id)
        
    reports = db.query(Report).filter(Report.family_unit_id == user.family_unit_id).order_by(Report.created_at.desc()).all()
    return {"reports": reports}

@router.get("/attachments/reports/{report_id}")
def download_report(report_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    from fastapi.responses import FileResponse
    
    report = db.query(Report).filter(
        Report.id == report_id,
        Report.family_unit_id == user.family_unit_id
    ).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    # Resolve local file path
    url = report.pdf_url
    if url.startswith("/"):
        url = url.lstrip("/")
    
    local_path = os.path.join(os.getcwd(), url)
    
    if os.path.exists(local_path):
        return FileResponse(local_path, media_type="application/pdf", filename=os.path.basename(local_path))
    
    raise HTTPException(status_code=404, detail="Report file not found on disk")