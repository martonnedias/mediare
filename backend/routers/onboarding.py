from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, field_validator
from .auth import verify_token
from database import get_db
from models import User, FamilyUnit, FamilyMember, Child
from datetime import datetime
from typing import Optional

router = APIRouter()

# Constantes de Modo de Uso
MODE_COLLABORATIVE = "collaborative"
MODE_UNILATERAL = "unilateral"
MODE_GAMIFICATION_ONLY = "gamification_only"

def validate_cpf_helper(v: str) -> str:
    if not v or not v.strip():
        raise ValueError('CPF é obrigatório')
    
    # Remove caracteres não numéricos
    cpf = ''.join(filter(str.isdigit, v))
    
    if len(cpf) != 11:
        raise ValueError('CPF deve ter 11 dígitos')
        
    # Bloqueia CPFs com todos os dígitos iguais
    if cpf == cpf[0] * 11:
        raise ValueError('CPF inválido')
        
    # Algoritmo de validação (Módulo 11)
    numbers = [int(digit) for digit in cpf]
    
    # Validação do primeiro dígito
    sum_val = sum(numbers[i] * (10 - i) for i in range(9))
    first_verifier = (sum_val * 10) % 11
    if first_verifier == 10: first_verifier = 0
    if first_verifier != numbers[9]:
        raise ValueError('CPF inválido')
        
    # Validação do segundo dígito
    sum_val = sum(numbers[i] * (11 - i) for i in range(10))
    second_verifier = (sum_val * 10) % 11
    if second_verifier == 10: second_verifier = 0
    if second_verifier != numbers[10]:
        raise ValueError('CPF inválido')
        
    return cpf

class CompleteProfileRequest(BaseModel):
    full_name: str
    cpf: str
    profile_picture: str
    
    @field_validator('full_name')
    @classmethod
    def validate_full_name(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError('Nome completo é obrigatório')
        if len(v.strip()) < 3:
            raise ValueError('Nome completo deve ter pelo menos 3 caracteres')
        return v.strip()
    
    @field_validator('cpf')
    @classmethod
    def validate_cpf(cls, v: str) -> str:
        return validate_cpf_helper(v)

@router.post("/onboarding/complete-profile")
def complete_profile(request: CompleteProfileRequest, db: Session = Depends(get_db), current_user: User = Depends(verify_token)):
    current_user.full_name = request.full_name
    current_user.cpf = request.cpf
    current_user.profile_picture = request.profile_picture
    
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    
    return {"message": "Profile completed successfully", "user_id": current_user.id}

class CreateFamilyRequest(BaseModel):
    name: str
    mode: str
    values_profile: Optional[str] = "Neutro/Educativo"
    children: list[dict]

    @field_validator('children')
    @classmethod
    def validate_children(cls, v: list[dict]) -> list[dict]:
        for child in v:
            if 'name' not in child or not child['name']:
                raise ValueError('O nome do filho é obrigatório')
            if 'cpf' not in child or not child['cpf']:
                raise ValueError('O CPF do filho é obrigatório')
            
            try:
                child['cpf'] = validate_cpf_helper(child['cpf'])
            except ValueError as e:
                raise ValueError(f'Filho {child.get("name", "")}: {str(e)}')
                
            if 'birth_date' not in child or not child['birth_date']:
                raise ValueError('A data de nascimento do filho é obrigatória')
            
            try:
                if isinstance(child['birth_date'], str):
                    child['birth_date'] = datetime.strptime(child['birth_date'], '%Y-%m-%d').date()
            except ValueError:
                raise ValueError(f"Data de nascimento inválida para {child.get('name')}. Use o formato AAAA-MM-DD.")
                
        return v

@router.post("/onboarding/create-family")
def create_family(request: CreateFamilyRequest, db: Session = Depends(get_db), current_user: User = Depends(verify_token)):
    if not current_user.cpf:
         raise HTTPException(status_code=400, detail="Complete profile first")
    
    family = FamilyUnit(
        name=request.name, 
        mode=request.mode, 
        values_profile=request.values_profile
    )
    db.add(family)
    db.commit()
    db.refresh(family)

    family_member = FamilyMember(user_id=current_user.id, family_id=family.id, role="parent")
    db.add(family_member)

    for child_data in request.children:
        try:
            bday = datetime.fromisoformat(child_data["birth_date"])
        except (ValueError, TypeError):
            bday = datetime.now()

        child = Child(
            name=child_data["name"],
            cpf=child_data["cpf"],
            birth_date=bday,
            interests=child_data.get("interests"),
            family_id=family.id
        )
        db.add(child)

    current_user.family_unit_id = family.id
    current_user.onboarding_completed = True
    db.add(current_user)

    db.commit()
    return {"message": "Family created successfully", "family_id": family.id}

@router.get("/families")
def list_families(user: User = Depends(verify_token), db: Session = Depends(get_db)):
    families = db.query(FamilyUnit).join(FamilyMember).filter(FamilyMember.user_id == user.id).all()
    return {"families": families}

class SwitchFamilyRequest(BaseModel):
    family_id: int

@router.post("/families/switch")
def switch_family(request: SwitchFamilyRequest, user: User = Depends(verify_token), db: Session = Depends(get_db)):
    family = db.query(FamilyUnit).join(FamilyMember).filter(
        FamilyMember.user_id == user.id, FamilyMember.family_id == request.family_id
    ).first()
    if not family:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Family not found or access denied")
    
    user.family_unit_id = family.id
    db.add(user)
    db.commit()
    return {"message": "Family switched successfully", "active_family": family.id}

class AddMemberRequest(BaseModel):
    email: str
    role: str = "parent"

@router.post("/families/{family_id}/members")
def add_family_member(family_id: int, request: AddMemberRequest, user: User = Depends(verify_token), db: Session = Depends(get_db)):
    is_member = db.query(FamilyMember).filter(FamilyMember.user_id == user.id, FamilyMember.family_id == family_id).first()
    if not is_member:
        raise HTTPException(status_code=403, detail="Acesso negado")
    
    target_user = db.query(User).filter(User.email == request.email).first()
    if not target_user:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    
    already_member = db.query(FamilyMember).filter(FamilyMember.user_id == target_user.id, FamilyMember.family_id == family_id).first()
    if already_member:
        raise HTTPException(status_code=400, detail="Usuário já é membro desta família")
    
    new_member = FamilyMember(user_id=target_user.id, family_id=family_id, role=request.role)
    db.add(new_member)
    db.commit()
    
    return {"message": "Membro adicionado com sucesso"}

class UpdateProfileRequest(BaseModel):
    full_name: Optional[str] = None
    profile_picture: Optional[str] = None

@router.put("/users/profile")
def update_profile(request: UpdateProfileRequest, user: User = Depends(verify_token), db: Session = Depends(get_db)):
    if request.full_name:
        user.full_name = request.full_name
    if request.profile_picture:
        user.profile_picture = request.profile_picture
    
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return {"message": "Perfil atualizado", "user": {"full_name": user.full_name, "profile_picture": user.profile_picture}}