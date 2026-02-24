from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from .auth import verify_token, check_family_access
from database import get_db
from models import CustodyCalendarRule, CustodyEvent, CheckIn, Child
from datetime import datetime, timedelta, timezone

router = APIRouter()

class CalendarRuleRequest(BaseModel):
    child_id: int
    rule_description: str
    start_time: str
    end_time: str

class EventCreateRequest(BaseModel):
    child_id: int
    event_date: str
    status: str = "scheduled"
    description: Optional[str] = None
    location_id: Optional[int] = None

@router.post("/calendar/events")
def create_event(request: EventCreateRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check: child belongs to family
    child = db.query(Child).filter(Child.id == request.child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Child not found or doesn't belong to your family.")
        
    try:
        dt = datetime.fromisoformat(request.event_date.replace('Z', '+00:00'))
    except:
        dt = datetime.now()

    event = CustodyEvent(
        family_unit_id=user.family_unit_id,
        child_id=request.child_id,
        event_date=dt,
        status=request.status,
        description=request.description,
        location_id=request.location_id
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return {"message": "Event created successfully", "event_id": event.id}

@router.post("/calendar/rules")
def create_calendar_rule(request: CalendarRuleRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check: child belongs to family
    child = db.query(Child).filter(Child.id == request.child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Child not found or doesn't belong to your family.")
        
    try:
        start_dt = datetime.fromisoformat(request.start_time.replace('Z', '+00:00'))
        end_dt = datetime.fromisoformat(request.end_time.replace('Z', '+00:00'))
    except:
        start_dt = datetime.now()
        end_dt = datetime.now() + timedelta(days=1)

    rule = CustodyCalendarRule(
        family_unit_id=user.family_unit_id,
        child_id=request.child_id,
        rule_description=request.rule_description,
        start_time=start_dt,
        end_time=end_dt
    )
    db.add(rule)
    db.commit()
    return {"message": "Calendar rule created successfully", "rule_id": rule.id}

@router.get("/calendar/events")
def list_events(start_date: str, end_date: str, family_unit_id: Optional[int] = None, child_id: Optional[int] = None, db: Session = Depends(get_db), user = Depends(verify_token)):
    fid = family_unit_id or user.family_unit_id
    
    # Security Check
    check_family_access(db, user.id, fid)
    
    query = db.query(CustodyEvent).filter(
        CustodyEvent.family_unit_id == fid,
        CustodyEvent.event_date >= start_date,
        CustodyEvent.event_date <= end_date
    )
    if child_id:
        query = query.filter(CustodyEvent.child_id == child_id)
    
    events = query.order_by(CustodyEvent.event_date.asc()).all()
    serialized = []
    for ev in events:
        checkins_data = [
            {
                "id": c.id,
                "timestamp": c.timestamp.isoformat() if hasattr(c.timestamp, 'isoformat') else str(c.timestamp),
                "latitude": c.latitude,
                "longitude": c.longitude,
                "status": c.status
            }
            for c in ev.checkins
        ]
        
        serialized.append({
            "id": ev.id,
            "child_id": ev.child_id,
            "event_date": ev.event_date.isoformat() if hasattr(ev.event_date, 'isoformat') else str(ev.event_date),
            "status": ev.status,
            "description": ev.description if hasattr(ev, 'description') else None,
            "location_id": ev.location_id,
            "location_name": ev.location.name if ev.location else None,
            "location_address": ev.location.address if ev.location else None,
            "location_type": ev.location.type if ev.location else None,
            "checkins": checkins_data
        })
    return {"events": serialized}


@router.get("/calendar/events/mock")
def mock_events():
    # Endpoint de desenvolvimento que retorna exemplos de eventos sem exigir autenticação
    now = datetime.now(timezone.utc)
    events = []
    for i in range(3):
        ev_date = now + timedelta(days=i)
        events.append({
            "id": 100 + i,
            "child_id": 1,
            "event_date": ev_date.isoformat(),
            "status": "scheduled",
            "description": f"Evento de teste #{i + 1}",
        })
    return {"events": events}

class CheckInRequest(BaseModel):
    event_id: int
    latitude: float
    longitude: float
    status: str

@router.post("/checkins")
def create_checkin(request: CheckInRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    event = db.query(CustodyEvent).filter(
        CustodyEvent.id == request.event_id,
        CustodyEvent.family_unit_id == user.family_unit_id
    ).first()
    if not event:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Event not found")

    checkin = CheckIn(
        event_id=request.event_id,
        timestamp=datetime.now(timezone.utc),
        latitude=request.latitude,
        longitude=request.longitude,
        status=request.status
    )
    db.add(checkin)
    db.commit()
    return {"message": "Check-in created successfully"}