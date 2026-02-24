import sys
import os
import pytest
import tempfile
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from datetime import datetime, timezone

# Ensure backend folder is in path
backend_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_path not in sys.path:
    sys.path.insert(0, backend_path)

from main import app
from database import Base, get_db
from routers.auth import verify_token
from models import User, FamilyUnit, FamilyMember, FamilyChat, Child

# Global variable to store temp DB path
_temp_db_path = None

@pytest.fixture(scope="session", autouse=True)
def engine():
    global _temp_db_path
    fd, _temp_db_path = tempfile.mkstemp(suffix=".db", prefix="mediare_test_")
    os.close(fd) # Close file descriptor but keep path
    
    db_url = f"sqlite:///{_temp_db_path}"
    engine = create_engine(db_url, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=engine)
    
    yield engine
    
    engine.dispose()
    if os.path.exists(_temp_db_path):
        try:
            os.remove(_temp_db_path)
        except:
            pass

@pytest.fixture(scope="session")
def TestingSessionLocal(engine):
    return sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture
def db_session(TestingSessionLocal):
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()

@pytest.fixture(autouse=True)
def setup_database(db_session):
    """
    Seeds a default User (id=1) in a default Family (id=1).
    This keeps existing tests working without manual seeding everywhere.
    """
    user = db_session.query(User).filter(User.id == 1).first()
    if not user:
        family = FamilyUnit(id=1, name="Test Family", mode="collaborative")
        db_session.add(family)
        db_session.commit()
        
        user = User(
            id=1,
            email="test@example.com",
            full_name="Test User",
            cpf="12345678901",
            hashed_password="hash",
            family_unit_id=1,
            onboarding_completed=True
        )
        db_session.add(user)
        
        member = FamilyMember(user_id=1, family_id=1, role="parent")
        db_session.add(member)
        
        # Seed Child for tests that expect id=1
        child = Child(
            id=1, 
            name="Test Child", 
            cpf="00000000000", 
            birth_date=datetime(2010, 1, 1),
            family_id=1
        )
        db_session.add(child)
        
        # Seed FamilyChat for test_chats.py
        chat = FamilyChat(id=1, family_unit_id=1, created_at=datetime.now(timezone.utc))
        db_session.add(chat)
        
        db_session.commit()

@pytest.fixture
def client(db_session):
    def override_get_db():
        yield db_session
    
    def override_verify_token():
        return db_session.query(User).filter(User.id == 1).first()

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[verify_token] = override_verify_token
    
    c = TestClient(app)
    c.headers.update({"Authorization": "Bearer mock_token"})
    yield c
