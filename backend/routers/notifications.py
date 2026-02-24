from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, ConfigDict
from .auth import verify_token
from database import get_db
from models import Notification
from datetime import datetime, timezone
from typing import List, Optional

router = APIRouter(prefix="/notifications", tags=["Notifications"])

class NotificationResponse(BaseModel):
    id: int
    title: str
    content: str
    type: str
    created_at: datetime
    read_at: Optional[datetime]

    model_config = ConfigDict(from_attributes=True)

class EmergencyRequest(BaseModel):
    latitude: float
    longitude: float
    message: Optional[str] = "EMERGÊNCIA MÉDICA ACIONADA"

@router.get("", response_model=List[NotificationResponse])
def list_notifications(db: Session = Depends(get_db), user = Depends(verify_token)):
    notifications = db.query(Notification).filter(
        Notification.family_unit_id == user.family_unit_id,
        Notification.user_id == user.id
    ).order_by(Notification.created_at.desc()).limit(20).all()
    return notifications

@router.post("/{notification_id}/read")
def mark_read(notification_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    notification = db.query(Notification).filter(Notification.id == notification_id, Notification.user_id == user.id).first()
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.read_at = datetime.now(timezone.utc)
    db.commit()
    return {"message": "Notification marked as read"}

from models import User

# Internal utility to create notifications
def create_internal_notification(db: Session, user_id: int, family_id: int, title: str, content: str, n_type: str = "info"):
    # Filtro de Resguardo: Ignore if the user has Do Not Disturb active
    user = db.query(User).filter(User.id == user_id).first()
    if user and getattr(user, 'resguardo_active', False):
        return

    new_notif = Notification(
        title=title,
        content=content,
        type=n_type,
        user_id=user_id,
        family_unit_id=family_id,
        created_at=datetime.now(timezone.utc)
    )
    db.add(new_notif)
    db.commit()

@router.post("/emergency")
def trigger_emergency(req: EmergencyRequest, db: Session = Depends(get_db), user: User = Depends(verify_token)):
    """
    Aciona o Botão de Pânico / Emergência Médica.
    Deve notificar os outros membros da família e possivelmente serviços cadastrados (futuro).
    """
    from models import FamilyMember
    if not user.family_unit_id:
        raise HTTPException(status_code=400, detail="User not in a family unit")
        
    other_members = db.query(FamilyMember).filter(
        FamilyMember.family_id == user.family_unit_id,
        FamilyMember.user_id != user.id
    ).all()
    
    base_msg = f"{req.message}. Coordenadas: {req.latitude}, {req.longitude}"
    
    for member in other_members:
        # Pula o filtro de resguardo para emergências reais se for mandatório, 
        # mas aqui vamos manter a assinatura. Idealmente emergência ignora resguardo.
        new_notif = Notification(
            title=f"🚨 ALERTA GERAL: {user.full_name}",
            content=base_msg,
            type="error",
            user_id=member.user_id,
            family_unit_id=user.family_unit_id,
            created_at=datetime.now(timezone.utc)
        )
        db.add(new_notif)
        
    db.commit()
    return {"message": "Emergency broadcasted successfully", "receivers": len(other_members)}
