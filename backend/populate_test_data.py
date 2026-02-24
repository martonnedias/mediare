import sys
import os
from datetime import datetime, date, timedelta

# Add parent dir to sys.path to import modules
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import engine, SessionLocal
from models import Base, User, FamilyUnit, FamilyMember, Child, Task, Reward, ChatMessage, Expense, Agreement

def populate():
    # Garantir que as tabelas existam
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        print("🚀 Iniciando população de dados de teste...")
        
        # 1. Create Test User
        user = db.query(User).filter(User.email == "teste@mediare.com").first()
        if not user:
            user = User(
                email="teste@mediare.com",
                hashed_password="hashed_password",
                full_name="Usuário de Teste",
                cpf="12345678901",
                onboarding_completed=True
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            print(f"✅ Usuário criado: {user.email}")
        
        # 2. Create Family Unit
        family = db.query(FamilyUnit).filter(FamilyUnit.name == "Família Exemplo").first()
        if not family:
            family = FamilyUnit(
                name="Família Exemplo",
                mode="collaborative",
                values_profile="Educação e Autonomia"
            )
            db.add(family)
            db.commit()
            db.refresh(family)
            print(f"✅ Família criada: {family.name}")
            
            # Link user to family
            member = FamilyMember(user_id=user.id, family_id=family.id, role="parent")
            db.add(member)
            user.family_unit_id = family.id
            db.add(user)
            db.commit()

        # 3. Create Child
        child = db.query(Child).filter(Child.name == "Lucas").first()
        if not child:
            child = Child(
                name="Lucas",
                cpf="98765432100",
                birth_date=date(2015, 6, 15),
                interests="Robótica e Futebol",
                family_id=family.id
            )
            db.add(child)
            db.commit()
            db.refresh(child)
            print(f"✅ Filho cadastrado: {child.name}")

        # 4. Create Missions (Tasks)
        if not db.query(Task).filter(Task.child_id == child.id).first():
            tasks = [
                Task(name="Arrumar a Cama", points=10, child_id=child.id, family_unit_id=family.id, status="pending", created_at=datetime.now()),
                Task(name="Lavar a Louça (Café)", points=15, child_id=child.id, family_unit_id=family.id, status="pending", created_at=datetime.now()),
                Task(name="Ler 15 min", points=20, child_id=child.id, family_unit_id=family.id, status="completed", created_at=datetime.now())
            ]
            db.add_all(tasks)
            print(f"✅ Missões adicionadas.")

        # 5. Create Rewards
        if not db.query(Reward).filter(Reward.family_unit_id == family.id).first():
            rewards = [
                Reward(name="Sorvete no Domingo", points_required=50, family_unit_id=family.id, created_at=datetime.now()),
                Reward(name="30min de Video Game", points_required=30, family_unit_id=family.id, created_at=datetime.now()),
                Reward(name="Escolher o Filme da Noite", points_required=40, family_unit_id=family.id, created_at=datetime.now())
            ]
            db.add_all(rewards)
            print(f"✅ Recompensas adicionadas.")

        # 6. Create Expense
        if not db.query(Expense).filter(Expense.family_unit_id == family.id).first():
            expense = Expense(
                description="Matériais Escolares",
                amount=250.00,
                status="Pendente",
                family_unit_id=family.id,
                child_id=child.id,
                created_at=datetime.now()
            )
            db.add(expense)
            print(f"✅ Despesa fictícia adicionada.")

        db.commit()
        print("\n🎉 Dados de teste prontos! Agora você pode logar com 'teste@mediare.com'.")

    except Exception as e:
        print(f"❌ Erro ao popular dados: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    populate()
