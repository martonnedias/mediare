import pytest
from unittest.mock import MagicMock, patch
from main import app
from database import get_db
from models import User, FamilyUnit, FamilyMember

# We rely on conftest.py for client and dependency overrides

# Test: Sincronização de Novo Usuário (Criação)
def test_sync_new_user(client, setup_database):
    # Mock do token decodificado
    with patch("routers.users.verify_firebase_token") as mock_verify:
        mock_verify.return_value = {
            "email": "newuser@example.com",
            "uid": "firebase_uid_123",
            "name": "New User",
            "picture": "http://pic.com/u.jpg"
        }

        # Chama o endpoint
        response = client.post("/users/sync")
        
        assert response.status_code == 200
        data = response.json()
        assert data["message"] == "User synced successfully"
        assert "user_id" in data
        assert data["onboarding_completed"] is False

# Teste: Sincronização de Usuário Existente
def test_sync_existing_user(client, setup_database):
    mock_email = "test@example.com" # User ID 1 exists from conftest
    
    with patch("routers.users.verify_firebase_token") as mock_verify:
        mock_verify.return_value = {
            "email": mock_email,
            "uid": "firebase_uid_456"
        }

        response = client.post("/users/sync")
        
        assert response.status_code == 200
        assert response.json()["onboarding_completed"] is True
        assert response.json()["user_id"] == 1

# Teste: Listar Famílias
def test_get_my_families(client, setup_database):
    response = client.get("/users/me/families")
    assert response.status_code == 200
    families = response.json()["families"]
    assert len(families) == 1
    assert families[0]["name"] == "Test Family"
