from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import User, FamilyUnit, FamilyMember, Child
from routers.auth import get_current_user, verify_firebase_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel
import datetime

router = APIRouter(prefix="/users", tags=["Users"])
security = HTTPBearer()

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    cpf: str
    profile_picture: str | None = None
    onboarding_completed: bool
    resguardo_active: bool

class UserProfileUpdate(BaseModel):
    full_name: str | None = None
    resguardo_active: bool | None = None

@router.post("/sync")
def sync_user(
    cred: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    """
    Syncs the Firebase user with the Postgres database.
    Creates the user if they don't exist.
    """
    token_data = verify_firebase_token(cred.credentials)
    email = token_data.get("email")
    uid = token_data.get("uid")
    name = token_data.get("name", "Usuário")
    picture = token_data.get("picture")
    
    if not email:
        raise HTTPException(status_code=400, detail="Token must contain email")
        
    user = db.query(User).filter(User.email == email).first()
    
    if not user:
        # Create new user
        user = User(
            email=email,
            hashed_password="firebase_managed", # Placeholder
            full_name=name,
            cpf=None,  # Preenchido no onboarding
            profile_picture=picture,
            onboarding_completed=False
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        # Robust check: if user has a family but onboarding_completed is False, fix it.
        if not user.onboarding_completed:
            from models import FamilyMember
            has_family = db.query(FamilyMember).filter(FamilyMember.user_id == user.id).first()
            if has_family or user.family_unit_id:
                user.onboarding_completed = True
                db.commit()
                db.refresh(user)
        
    return {
        "message": "User synced successfully",
        "user_id": user.id,
        "onboarding_completed": user.onboarding_completed
    }

@router.get("/me", response_model=UserResponse)
def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "full_name": current_user.full_name,
        "cpf": current_user.cpf,
        "profile_picture": current_user.profile_picture,
        "onboarding_completed": current_user.onboarding_completed,
        "resguardo_active": current_user.resguardo_active
    }

@router.put("/profile")
def update_profile(
    data: UserProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if data.full_name is not None:
        current_user.full_name = data.full_name
    if data.resguardo_active is not None:
        current_user.resguardo_active = data.resguardo_active
        
    db.commit()
    return {"message": "Profile updated successfully"}

@router.get("/me/families")
def get_my_families(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    memberships = db.query(FamilyMember).filter(FamilyMember.user_id == current_user.id).all()
    families = []
    
    for member in memberships:
        family = db.query(FamilyUnit).filter(FamilyUnit.id == member.family_id).first()
        if family:
            families.append({
                "id": family.id,
                "name": family.name,
                "mode": family.mode,
                "role": member.role
            })
            
    return {"families": families}

class ChildUpdate(BaseModel):
    name: str | None = None
    interests: str | None = None

@router.get("/children")
def get_children(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not current_user.family_unit_id:
        return {"children": []}
    
    children = db.query(Child).filter(Child.family_id == current_user.family_unit_id).all()
    serialized = []
    for c in children:
        serialized.append({
            "id": c.id,
            "name": c.name,
            "cpf": c.cpf,
            "birth_date": c.birth_date.isoformat() if c.birth_date else None,
            "interests": c.interests
        })
    return {"children": serialized}

@router.put("/children/{child_id}")
def update_child(
    child_id: int,
    data: ChildUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    child = db.query(Child).filter(Child.id == child_id, Child.family_id == current_user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=404, detail="Child not found")
        
    if data.name is not None:
        child.name = data.name
    if data.interests is not None:
        child.interests = data.interests
        
    db.commit()
    return {"message": "Child updated successfully"}

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_my_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Apple Compliance & LGPD: Soft deletes user account and scrubs sensitive PII where possible
    while retaining audit-ready hashed data.
    """
    # 1. Soft delete the user
    current_user.deleted_at = datetime.datetime.utcnow()
    
    # 2. Mask critical PII (LGPD right to be forgotten snippet, leaving audit log integerity)
    orig_em = current_user.email
    current_user.email = f"deleted_{current_user.id}@mediare.local"
    if current_user.cpf:
        current_user.cpf = "***.***.***-**"
    if current_user.full_name:
        current_user.full_name = "Conta Removida"
        
    db.commit()
    return None
