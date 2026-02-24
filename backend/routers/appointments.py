from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from .auth import verify_token, check_family_access
from database import get_db
from models import Appointment, AppointmentChecklist, AppointmentChecklistStatus, AppointmentStatusHistory
from datetime import datetime, timezone
from .notifications import create_internal_notification

router = APIRouter()

class AppointmentRequest(BaseModel):
    type: str
    description: str = None
    scheduled_time: str
    family_unit_id: int
    location_id: int = None

@router.post("/appointments")
def create_appointment(request: AppointmentRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    check_family_access(db, user.id, request.family_unit_id)
    
    appointment = Appointment(
        type=request.type,
        description=request.description,
        scheduled_time=request.scheduled_time,
        family_unit_id=request.family_unit_id,
        location_id=request.location_id,
        created_at=datetime.now(timezone.utc),
        status='scheduled'
    )
    db.add(appointment)
    db.commit()
    db.refresh(appointment)
    
    # Notify user
    create_internal_notification(
        db, user.id, request.family_unit_id, 
        "Novo Compromisso", 
        f"Foi agendado: {request.type} - {request.description}",
        "info"
    )
    
    return {"message": "Appointment created successfully", "appointment_id": appointment.id}

class AppointmentStatusRequest(BaseModel):
    status: str  # scheduled, confirmed, in_progress, completed, late, canceled, etc.

@router.post("/appointments/{appointment_id}/status")
def update_appointment_status(appointment_id: int, request: AppointmentStatusRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id, Appointment.family_unit_id == user.family_unit_id).first()
    if not appointment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Appointment not found")

    # Security Check
    check_family_access(db, user.id, appointment.family_unit_id)
    
    # Update status and add to history
    appointment.status = request.status
    status_history = AppointmentStatusHistory(
        appointment_id=appointment.id,
        status=request.status,
        changed_at=datetime.now(timezone.utc)
    )
    db.add(status_history)
    db.commit()
    return {"message": "Appointment status updated successfully", "appointment_id": appointment.id, "status": appointment.status}

@router.get("/appointments")
def list_appointments(family_unit_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    check_family_access(db, user.id, family_unit_id)
    
    appointments = db.query(Appointment).filter(Appointment.family_unit_id == family_unit_id).all()
    serialized = []
    for appt in appointments:
        serialized.append({
            "id": appt.id,
            "type": appt.type,
            "description": appt.description,
            "scheduled_time": appt.scheduled_time.isoformat() if hasattr(appt.scheduled_time, 'isoformat') else str(appt.scheduled_time),
            "status": appt.status,
            "location_id": appt.location_id,
            "location_name": appt.location.name if appt.location else None,
            "location_address": appt.location.address if appt.location else None,
            "location_type": appt.location.type if appt.location else None,
        })
    return {"appointments": serialized}