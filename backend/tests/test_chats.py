import pytest
from unittest.mock import patch, MagicMock
import os
import json

# We rely on conftest.py for client and dependency overrides

def test_send_message_allowed(client, setup_database):
    # Mock Google Generative AI response (if genai_client is used)
    # The routers/chats.py uses ai_utils.gemini_client
    with patch("ai_utils.gemini_client.analyze_json") as mock_analyze:
        mock_analyze.return_value = {"toxicity_score": 0.1, "status": "allowed", "reason": "OK"}
        
        response = client.post(
            "/chats/messages",
            json={"chat_id": 1, "content": "Olá, tudo bem?"}
        )
        assert response.status_code == 200
        assert response.json()["moderation_status"] == "allowed"

def test_send_message_blocked_ai(client, setup_database):
    with patch("ai_utils.gemini_client.analyze_json") as mock_analyze:
        mock_analyze.return_value = {"toxicity_score": 0.9, "status": "blocked", "reason": "Ofensivo"}
        
        response = client.post(
            "/chats/messages",
            json={"chat_id": 1, "content": "Você é horrível"}
        )
        assert response.status_code == 400
        assert "Mensagem bloqueada" in response.json()["detail"]

def test_send_message_fallback(client, setup_database):
    # Mock analyze_json returning None to trigger fallback
    with patch("ai_utils.gemini_client.analyze_json") as mock_analyze:
        mock_analyze.return_value = None
        
        response = client.post(
            "/chats/messages",
            json={"chat_id": 1, "content": "Seu idiota"}
        )
        assert response.status_code == 400
        assert "Mensagem bloqueada" in response.json()["detail"]
