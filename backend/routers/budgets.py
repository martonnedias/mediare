from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from routers.auth import verify_token, check_family_access
from database import get_db
from models import Budget, BudgetAnalysis, BudgetNegotiation, FamilyMember
from routers.notifications import create_internal_notification
from ai_utils import gemini_client
import os
from datetime import datetime, timezone
from typing import Optional

router = APIRouter()

# AI Configuration (Gemini) removed - using ai_utils

@router.post("/budgets/{budget_id}/analyze")
def analyze_budget(budget_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    budget = db.query(Budget).filter(Budget.id == budget_id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")
    
    # Security check: Does user belong to family of this budget?
    check_family_access(db, user.id, budget.family_unit_id)

    prompt = f"""
    Analise este orçamento familiar e dê uma recomendação neutra e justa:
    Descrição: {budget.description}
    Valor Estimado: R$ {budget.estimated_value:.2f}
    
    Responda em formato JSON com 'analysis' (texto curto) e 'recommendation' (approve, negotiate, reject).
    """

    new_analysis_data = gemini_client.analyze_json(prompt)
    
    if new_analysis_data:
        analysis_text = new_analysis_data.get("analysis", "Análise processada.")
        recommendation = new_analysis_data.get("recommendation", "negotiate")
    else:
        analysis_text = "Análise simulada: O valor parece estar dentro da média de mercado."
        recommendation = "approve"

    new_analysis = BudgetAnalysis(
        budget_id=budget_id,
        analysis_text=analysis_text,
        suggested_action=recommendation,
        created_at=datetime.now(timezone.utc)
    )
    db.add(new_analysis)
    db.commit()

    return {"analysis": analysis_text, "recommendation": recommendation}

class BudgetRequest(BaseModel):
    description: str
    estimated_value: float
    child_id: Optional[int] = None
    family_unit_id: int

@router.post("/budgets")
def create_budget(request: BudgetRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check: User must be member of family_unit_id
    check_family_access(db, user.id, request.family_unit_id)
    
    budget = Budget(
        description=request.description,
        estimated_value=request.estimated_value,
        child_id=request.child_id,
        family_unit_id=request.family_unit_id,
        created_at=datetime.now(timezone.utc)
    )
    db.add(budget)
    db.commit()
    db.refresh(budget)

    # Notificar o outro genitor
    other_member = db.query(FamilyMember).filter(
        FamilyMember.family_id == request.family_unit_id,
        FamilyMember.user_id != user.id
    ).first()
    
    if other_member:
        create_internal_notification(
            db, other_member.user_id, request.family_unit_id,
            "Novo Orçamento Sugerido",
            f"Um novo orçamento '{request.description}' no valor de R$ {request.estimated_value:.2f} foi proposto.",
            "info"
        )

    return {"message": "Budget created successfully", "budget_id": budget.id}

class BudgetStatusRequest(BaseModel):
    status: str  # proposed, approved, rejected, canceled

@router.put("/budgets/{budget_id}/status")
def update_budget_status(budget_id: int, request: BudgetStatusRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    budget = db.query(Budget).filter(Budget.id == budget_id).first()
    if not budget:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Budget not found")

    # Security check
    check_family_access(db, user.id, budget.family_unit_id)
    
    budget.status = request.status
    db.commit()

    # Notificar interessados
    other_member = db.query(FamilyMember).filter(
        FamilyMember.family_id == budget.family_unit_id,
        FamilyMember.user_id != user.id
    ).first()
    
    if other_member:
        create_internal_notification(
            db, other_member.user_id, budget.family_unit_id,
            "Status de Orçamento Atualizado",
            f"O orçamento '{budget.description}' foi marcado como {request.status}.",
            "warning" if request.status in ['rejected', 'canceled'] else "success"
        )

    return {"message": "Budget status updated successfully", "budget_id": budget.id, "status": budget.status}

class NegotiationRequest(BaseModel):
    comment: str
    counter_offer: Optional[float] = None

@router.post("/budgets/{budget_id}/negotiate")
def negotiate_budget(budget_id: int, request: NegotiationRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    budget = db.query(Budget).filter(Budget.id == budget_id).first()
    if not budget:
        raise HTTPException(status_code=404, detail="Budget not found")

    # Security check
    check_family_access(db, user.id, budget.family_unit_id)
    
    negotiation = BudgetNegotiation(
        budget_id=budget_id,
        user_id=user.id,
        comment=request.comment,
        counter_offer=request.counter_offer,
        created_at=datetime.now(timezone.utc)
    )
    db.add(negotiation)
    budget.status = 'negotiating'
    db.commit()

    # Notificar o proponente
    other_member = db.query(FamilyMember).filter(
        FamilyMember.family_id == budget.family_unit_id,
        FamilyMember.user_id != user.id
    ).first()
    
    if other_member:
        create_internal_notification(
            db, other_member.user_id, budget.family_unit_id,
            "Contra-proposta de Orçamento",
            f"Recebida contra-proposta para '{budget.description}': {request.comment}",
            "info"
        )

    return {"message": "Negotiation recorded"}

@router.get("/budgets")
def list_budgets(family_unit_id: int, status: Optional[str] = None, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check
    check_family_access(db, user.id, family_unit_id)
    
    query = db.query(Budget).filter(Budget.family_unit_id == family_unit_id)
    if status:
        query = query.filter(Budget.status == status)
    budgets = query.all()
    return {"budgets": budgets}