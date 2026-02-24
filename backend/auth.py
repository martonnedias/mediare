from fastapi import Depends, HTTPException, status
from firebase_admin import auth, initialize_app
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from .database import get_db
from .models import User

# Firebase initialization
try:
    initialize_app()
except ValueError:
    pass

SECRET_KEY = "your_secret_key"
ALGORITHM = "HS256"

def verify_token(token: str, db: Session = Depends(get_db)):
    try:
        decoded_token = auth.verify_id_token(token)
        user_email = decoded_token.get("email")
        if user_email is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
            )
        user = db.query(User).filter(User.email == user_email).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
            )
        return user
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
        )