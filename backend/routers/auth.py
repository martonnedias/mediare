from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from firebase_admin import auth, initialize_app, credentials
from jose import JWTError
from database import get_db
from models import User, FamilyMember
import os

router = APIRouter(tags=["Auth"])

from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# Inicializa o Firebase Admin SDK com credenciais do Service Account
_cred_path = os.path.join(os.path.dirname(__file__), '..', 'mediare-8be4c-firebase-adminsdk-fbsvc-a6a6ab6335.json')
try:
    cred = credentials.Certificate(_cred_path)
    initialize_app(cred)
except ValueError:
    # App already initialized
    pass

security = HTTPBearer()

def verify_firebase_token(token: str) -> dict:
    # Bypass para desenvolvimento/testes
    if token == "mock_dev_token":
        return {"email": "martonne.mdc@gmail.com", "uid": "mock_uid", "name": "Usuário Teste"}
        
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        print(f"DEBUG: Firebase Error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Não foi possível validar as credenciais do Firebase."
        )

def get_current_user(cred: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    token_data = verify_firebase_token(cred.credentials)
    user_email = token_data.get("email")
    if not user_email:
        raise HTTPException(status_code=401, detail="Token inválido (sem email)")
    
    user = db.query(User).filter(User.email == user_email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Usuário não encontrado."
        )
    return user

# Alias logging for backward compatibility if needed, or just replace usage
verify_token = get_current_user

def check_family_access(db: Session, user_id: int, family_id: int):
    """
    Raises 403 Forbidden if the user is not a member of the family_id.
    """
    membership = db.query(FamilyMember).filter(
        FamilyMember.user_id == user_id,
        FamilyMember.family_id == family_id
    ).first()
    
    if not membership:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso negado: Você não é membro desta unidade familiar."
        )
