import pytest
from main import app
from models import User

# We rely on conftest.py for client and dependency overrides

def test_complete_profile(client, setup_database):
    response = client.post(
        "/onboarding/complete-profile",
        json={
            "full_name": "Test User Updated",
            "cpf": "52998224725", # Raw CPF
            "profile_picture": "https://example.com/picture.jpg"
        },
        headers={"Authorization": "Bearer test_token"}
    )
    assert response.status_code == 200
    assert response.json()["message"] == "Profile completed successfully"