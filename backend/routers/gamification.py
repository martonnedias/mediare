from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from routers.auth import verify_token, check_family_access
from database import get_db
from models import Task, Reward, ChildPointsLedger, ChildLevel
from datetime import datetime, timezone

router = APIRouter()

from typing import Optional

class TaskRequest(BaseModel):
    name: str
    description: Optional[str] = None
    points: int
    child_id: int

@router.post("/tasks")
def create_task(request: TaskRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check: child belongs to family
    from models import Child
    child = db.query(Child).filter(Child.id == request.child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Child not found or doesn't belong to your family.")

    task = Task(
        name=request.name,
        description=request.description,
        points=request.points,
        child_id=request.child_id,
        family_unit_id=user.family_unit_id,
        status='pending',
        created_at=datetime.now(timezone.utc)
    )
    db.add(task)
    db.commit()
    db.refresh(task)
    return {"message": "Task created successfully", "task_id": task.id}

@router.get("/tasks/suggest-ai")
def suggest_tasks_ai(child_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    """Sugere tarefas lúdicas e educativas usando o Gemini."""
    from ai_utils import gemini_client
    from models import Child
    import json
    
    child = db.query(Child).filter(Child.id == child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Acesso negado: Você não tem permissão para ver esta criança.")
    
    # Calcula idade aproximada
    age = datetime.now().year - child.birth_date.year
    
    prompt = f"""
    Você é um coach de educação infantil e gamificação.
    Sugira 3 tarefas educativas e lúdicas para uma criança de {age} anos chamada {child.name}.
    O objetivo é ajudar na disciplina e autonomia.
    
    Retorne APENAS um JSON (sem markdown) no seguinte formato:
    [
      {{"name": "Nome Lúdico da Tarefa", "description": "Descrição curta e motivadora", "points": 20}},
      ...
    ]
    """
    
    suggestions = gemini_client.analyze_json(prompt)
    
    if not suggestions:
        # Fallback se a IA falhar
        suggestions = [
            {"name": "Missão Quarto Brilhante", "description": "Organizar os brinquedos no baú", "points": 15},
            {"name": "Mestre da Leitura", "description": "Ler 5 páginas de um livro", "points": 20},
            {"name": "Ajudante Real", "description": "Ajudar a colocar a mesa para o jantar", "points": 10}
        ]
        
    return {"child_name": child.name, "suggestions": suggestions}

from routers.notifications import create_internal_notification

@router.post("/tasks/{task_id}/complete")
def complete_task(task_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    task = db.query(Task).filter(Task.id == task_id, Task.family_unit_id == user.family_unit_id).first()
    if not task:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Task not found")

    task.status = 'completed'
    db.commit()
    
    # Notify parents
    create_internal_notification(
        db, user.id, user.family_unit_id, 
        "Missão Cumprida!", 
        f"A tarefa '{task.name}' foi marcada como concluída.",
        "success"
    )

    # Add points to ledger
    ledger_entry = ChildPointsLedger(
        child_id=task.child_id,
        points=task.points,
        description=f"Completed task: {task.name}",
        created_at=datetime.now(timezone.utc)
    )
    db.add(ledger_entry)

    # Update child level
    child_level = db.query(ChildLevel).filter(ChildLevel.child_id == task.child_id).first()
    if not child_level:
        child_level = ChildLevel(child_id=task.child_id, level=1, points=0)
        db.add(child_level)

    child_level.points += task.points
    if child_level.points >= 100:  # Example: 100 points to level up
        child_level.level += 1
        child_level.points -= 100

    db.commit()
    return {"message": "Task completed and points added", "task_id": task.id, "child_level": child_level.level}

@router.get("/tasks")
def list_tasks(child_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check: child belongs to family
    from models import Child
    child = db.query(Child).filter(Child.id == child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Acesso negado.")
        
    tasks = db.query(Task).filter(Task.child_id == child_id, Task.family_unit_id == user.family_unit_id).all()
    return {"tasks": tasks}

@router.delete("/tasks/{task_id}")
def delete_task(task_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    task = db.query(Task).filter(Task.id == task_id, Task.family_unit_id == user.family_unit_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="Missão não encontrada")
    db.delete(task)
    db.commit()
    return {"message": "Missão removida"}

@router.get("/child-progress/{child_id}")
def get_child_progress(child_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check
    from models import Child
    child = db.query(Child).filter(Child.id == child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Acesso negado.")

    child_level = db.query(ChildLevel).filter(ChildLevel.child_id == child_id).first()
    if not child_level:
        return {"level": 1, "points": 0, "next_level_points": 100}
    
    return {
        "level": child_level.level,
        "points": child_level.points,
        "next_level_points": 100
    }

@router.get("/child-progress/{child_id}/encouragement")
def get_child_encouragement(child_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    """Gera uma mensagem de incentivo personalizada via IA baseada no progresso da criança."""
    from ai_utils import gemini_client
    from models import Child, ChildLevel, Task, FamilyUnit
    
    child = db.query(Child).filter(Child.id == child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Acesso negado.")
        
    child_level = db.query(ChildLevel).filter(ChildLevel.child_id == child_id).first()
        
    recent_tasks = db.query(Task).filter(Task.child_id == child_id, Task.status == 'completed').order_by(Task.created_at.desc()).limit(3).all()
    tasks_str = ", ".join([t.name for t in recent_tasks]) or "iniciando novas missões"
    
    values = family.values_profile if family else "educação e harmonia"
    
    prompt = f"""
    Você é o 'Guardião da Harmonia', um mentor virtual super legal para crianças.
    Escreva uma mensagem curta (máximo 2 linhas) de incentivo para {child.name}.
    
    CONTEXTO:
    - Nível atual: {child_level.level if child_level else 1}
    - Missões recentes cumpridas: {tasks_str}
    - Valores da família: {values}
    
    A mensagem deve ser empolgante, usar emojis e reforçar o valor de ser um membro colaborativo da família.
    Retorne APENAS o texto da mensagem.
    """
    
    encouragement = gemini_client.generate_content(prompt)
    if not encouragement:
        encouragement = f"Continue assim, {child.name}! Você está se tornando um verdadeiro herói da colaboração! ✨🚀"
        
    return {"message": encouragement}

class RewardRequest(BaseModel):
    name: str
    description: Optional[str] = None
    points_required: int

@router.post("/rewards")
def create_reward(request: RewardRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    reward = Reward(
        name=request.name,
        description=request.description,
        points_required=request.points_required,
        family_unit_id=user.family_unit_id,
        created_at=datetime.now(timezone.utc)
    )
    db.add(reward)
    db.commit()
    db.refresh(reward)
    return {"message": "Reward created successfully", "reward_id": reward.id}

@router.get("/rewards")
def list_rewards(db: Session = Depends(get_db), user = Depends(verify_token)):
    rewards = db.query(Reward).filter(Reward.family_unit_id == user.family_unit_id).all()
    return {"rewards": rewards}

@router.delete("/rewards/{reward_id}")
def delete_reward(reward_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    reward = db.query(Reward).filter(Reward.id == reward_id, Reward.family_unit_id == user.family_unit_id).first()
    if not reward:
        raise HTTPException(status_code=404, detail="Recompensa não encontrada")
    db.delete(reward)
    db.commit()
    return {"message": "Recompensa removida"}

@router.get("/child-discovery")
def get_child_discovery(child_id: int, city: str, db: Session = Depends(get_db), user = Depends(verify_token)):
    """
    Motor de Descobertas IA: Pesquisa eventos, filmes e notícias 
    baseados nos interesses da criança e nos valores da família.
    """
    from ai_utils import gemini_client
    from models import Child, FamilyUnit
    
    child = db.query(Child).filter(Child.id == child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Acesso negado.")
        
    family = db.query(FamilyUnit).filter(FamilyUnit.id == user.family_unit_id).first()

    interests = child.interests or "Atividades educativas e lazer"
    values = family.values_profile or "neutro/educativo"
    
    prompt = f"""
    Como um guia infantil especializado, pesquise eventos e atividades reais na cidade de {city} para esta semana.
    
    PERFIL DA CRIANÇA:
    - Nome: {child.name}
    - Idade: {datetime.now().year - child.birth_date.year} anos
    - Interesses cadastrados: {interests}
    
    PERFIL DE VALORES DA FAMÍLIA:
    - Princípios: {values}
    
    REGRAS ESTREITAS:
    1. Sugira apenas eventos que respeitem os valores da família ({values}).
    2. Evite qualquer conteúdo que viole a ética ou segurança infantil.
    3. Inclua: Eventos do dia/semana, Filmes em cartaz, Parques ou atrações novas.
    4. Forneça links de referência para cada sugestão.
    
    Retorne um JSON estruturado com:
    - summary: um breve texto introdutório motivador.
    - categories: [
        {{"category": "Eventos", "items": [{{"title": "...", "date": "...", "link": "...", "description": "..."}}]}},
        {{"category": "Cinema/Cultura", "items": [...]}},
        {{"category": "Dicas de Estudo/News", "items": [...]}}
      ]
    """
    
    discovery_data = gemini_client.analyze_json(prompt)
    
    if not discovery_data:
        return {"message": "A IA está processando as novidades, tente em instantes.", "status": "processing"}
        
    return discovery_data

@router.post("/rewards/{reward_id}/redeem")
def redeem_reward(reward_id: int, child_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security check: child belongs to family
    from models import Child
    child = db.query(Child).filter(Child.id == child_id, Child.family_id == user.family_unit_id).first()
    if not child:
        raise HTTPException(status_code=403, detail="Child not found or doesn't belong to your family.")

    reward = db.query(Reward).filter(Reward.id == reward_id, Reward.family_unit_id == user.family_unit_id).first()
    if not reward:
        raise HTTPException(status_code=404, detail="Reward not found")
        
    child_level = db.query(ChildLevel).filter(ChildLevel.child_id == child_id).first()
    if not child_level or child_level.points < reward.points_required:
        raise HTTPException(status_code=400, detail="Insufficient points")
        
    # Deduct points
    child_level.points -= reward.points_required
    
    # Ledger entry
    ledger = ChildPointsLedger(
        child_id=child_id,
        points=-reward.points_required,
        description=f"Redeemed reward: {reward.name}",
        created_at=datetime.now(timezone.utc)
    )
    db.add(ledger)
    
    # Notify parents
    create_internal_notification(
        db, user.id, user.family_unit_id,
        "Recompensa Resgatada! 🎁",
        f"A recompensa '{reward.name}' foi resgatada.",
        "info"
    )
    
    db.commit()
    return {"message": "Reward redeemed successfully", "new_balance": child_level.points}

@router.get("/gamification/harmony-insight")
def get_family_harmony_insight(db: Session = Depends(get_db), user = Depends(verify_token)):
    """Analisa o engajamento da família na gamificação e chat para dar um 'termômetro' de harmonia."""
    from ai_utils import gemini_client
    from models import EventLog, FamilyUnit
    
    family = db.query(FamilyUnit).filter(FamilyUnit.id == user.family_unit_id).first()
    recent_events = db.query(EventLog).filter(EventLog.family_unit_id == user.family_unit_id).order_by(EventLog.created_at.desc()).limit(10).all()
    
    events_summary = ", ".join([e.event_type for e in recent_events]) if recent_events else "início das atividades"
    
    prompt = f"""
    Você é um consultor de harmonia familiar de alto nível.
    Analise o clima da família baseando-se nestes eventos recentes: {events_summary}.
    Perfil da família: {family.values_profile if family else 'Geral'}.
    
    Escreva um Insight de 1 frase curta para os pais sobre como melhorar a convivência ou elogiar o progresso.
    O tom deve ser inspirador e diplomático.
    
    Retorne APENAS a frase curta.
    """
    
    insight = gemini_client.generate_content(prompt)
    if not insight:
        insight = "A colaboração é o alicerce para um futuro brilhante para seus filhos. Continuem firmes!"
        
    return {"insight": insight}