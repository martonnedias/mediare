from fastapi import APIRouter, Depends, HTTPException, status, Form, UploadFile, File
from sqlalchemy.orm import Session
from pydantic import BaseModel
from .auth import verify_token, check_family_access
from database import get_db
from models import FamilyChat, ChatMessage, ChatMessageRead
from datetime import datetime, timezone
import json
import random # For mock scores if OpenAI key is missing
import os

router = APIRouter()

# OpenAI GPT-4 Configuration (Placeholder)
OPENAI_API_KEY = "your_openai_api_key"

class ChatMessageRequest(BaseModel):
    chat_id: int
    content: str

@router.post("/chats/messages/audio")
async def send_audio_message(
    chat_id: int = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    user = Depends(verify_token)
):
    """Envia uma mensagem de áudio com moderação automática via IA."""
    # Security Check
    chat = db.query(FamilyChat).filter(FamilyChat.id == chat_id).first()
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    check_family_access(db, user.id, chat.family_unit_id)
    
    from ai_utils import gemini_client
    
    audio_content = await file.read()
    
    prompt = """
    Você é um moderador de chat familiar e transcritor inteligente.
    Analise o áudio anexado. Sua missão é:
    1. Transcrever o áudio fielmente.
    2. Analisar a toxicidade e o sentimento.
    
    Retorne APENAS um JSON (sem markdown) com os campos:
    - transcription: str (o texto falado)
    - toxicity_score: float (0.0 a 1.0)
    - status: str ("allowed", "blocked")
    - reason: str (breve explicação se bloqueado)
    """
    
    analysis = gemini_client.analyze_audio(prompt, audio_content, mime_type=file.content_type)
    
    if not analysis or analysis.get("status") == "blocked":
        reason = analysis.get("reason", "Conteúdo inadequado detectado no áudio.") if analysis else "Erro ao processar áudio."
        raise HTTPException(status_code=400, detail=f"Áudio bloqueado. Motivo: {reason}")
        
    transcription = analysis.get("transcription", "")
    
    # Save as message (using transcription as content for now, plus an indicator that it was audio)
    message = ChatMessage(
        chat_id=chat_id,
        sender_id=user.id,
        content=f"[Áudio: {transcription}]", 
        toxicity_score=analysis.get("toxicity_score", 0.0),
        moderation_status="allowed",
        created_at=datetime.now(timezone.utc)
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    
    return {"message": "Audio sent successfully", "transcription": transcription, "message_id": message.id}

@router.post("/chats/messages")
def send_message(request: ChatMessageRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    chat = db.query(FamilyChat).filter(FamilyChat.id == request.chat_id).first()
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    check_family_access(db, user.id, chat.family_unit_id)
    
    from ai_utils import gemini_client
    
    toxicity_score = 0.0
    sentiment_score = 0.0
    moderation_status = "allowed"
    ai_analysis = "Análise automática"

    prompt = f"""
    Analise a seguinte mensagem em um contexto de chat familiar (pais divorciados/filhos, monitorado judicialmente).
    Mensagem: "{request.content}"
    
    Retorne APENAS um JSON (sem markdown, sem aspas triplas) com os campos:
    - toxicity_score: float (0.0 a 1.0, onde 1.0 é extremamente tóxico/ofensivo)
    - sentiment_score: float (-1.0 negativo a 1.0 positivo)
    - reason: str (breve explicação)
    - status: str ("allowed", "needs_rewrite", "blocked")
    """
    
    analysis = gemini_client.analyze_json(prompt)
    
    if analysis:
        toxicity_score = analysis.get("toxicity_score", 0.0)
        sentiment_score = analysis.get("sentiment_score", 0.0)
        moderation_status = analysis.get("status", "allowed")
        ai_analysis = analysis.get("reason", "Análise IA")
    else:
        # Fallback to simple keyword check if AI fails or key is missing
        toxic_words = ["idiota", "burro", "estúpido", "imbecil", "retardado"]
        if any(word in request.content.lower() for word in toxic_words):
            toxicity_score = 0.9
            moderation_status = "blocked"
            ai_analysis = "Bloqueado por filtro de palavras ofensivas (fallback)"

    if moderation_status == "blocked":
        # We save it as blocked but return an error to the user
        message = ChatMessage(
            chat_id=request.chat_id,
            sender_id=user.id,
            content=request.content,
            toxicity_score=toxicity_score,
            sentiment_score=sentiment_score,
            moderation_status=moderation_status,
            created_at=datetime.now(timezone.utc)
        )
        db.add(message)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail=f"Mensagem bloqueada. Motivo: {ai_analysis}"
        )

    # Save message
    message = ChatMessage(
        chat_id=request.chat_id,
        sender_id=user.id,
        content=request.content,
        toxicity_score=toxicity_score,
        sentiment_score=sentiment_score,
        moderation_status=moderation_status,
        created_at=datetime.now(timezone.utc)
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return {
        "message": "Message sent successfully", 
        "message_id": message.id, 
        "moderation_status": moderation_status,
        "toxicity_score": toxicity_score
    }

@router.get("/chats/messages")
def list_messages(chat_id: int, page: int = 1, page_size: int = 50, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    chat = db.query(FamilyChat).filter(FamilyChat.id == chat_id).first()
    if not chat:
        raise HTTPException(status_code=404, detail="Chat not found")
    check_family_access(db, user.id, chat.family_unit_id)
    
    messages = db.query(ChatMessage).filter(
        ChatMessage.chat_id == chat_id,
        ChatMessage.moderation_status != "blocked"
    ).order_by(ChatMessage.created_at.asc()).offset((page - 1) * page_size).limit(page_size).all()
    return {"messages": messages}

class ReadMessageRequest(BaseModel):
    message_id: int

@router.post("/chats/messages/{message_id}/read")
def mark_message_as_read(request: ReadMessageRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    read_receipt = ChatMessageRead(
        message_id=request.message_id,
        user_id=user.id,
        read_at=datetime.now(timezone.utc)
    )
    db.add(read_receipt)
    db.commit()
    return {"message": "Message marked as read"}