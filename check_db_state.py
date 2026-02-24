from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
import models
import os

DATABASE_URL = "sqlite:///./mediare.db"

def check_db():
    print(f"📂 Verificando banco de dados: {os.path.abspath('mediare.db')}")
    if not os.path.exists("mediare.db"):
        print("❌ Banco de dados não encontrado!")
        return

    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()

    try:
        users = db.query(models.User).all()
        print(f"👤 Total de usuários: {len(users)}")
        for u in users:
            print(f"   - {u.email} (ID: {u.id}, Onboarding: {u.onboarding_completed})")
        
        families = db.query(models.FamilyUnit).all()
        print(f"🏠 Total de famílias: {len(families)}")
        for f in families:
            print(f"   - {f.name} (ID: {f.id})")

    except Exception as e:
        print(f"❌ Erro ao ler banco: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_db()
