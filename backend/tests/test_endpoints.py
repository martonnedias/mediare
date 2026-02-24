import pytest

def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_get_notifications(client):
    response = client.get("/notifications")
    assert response.status_code == 200
    assert isinstance(response.json(), list)

def test_generate_ai_agreement(client):
    response = client.post(
        "/agreements/suggest",
        json={
            "conflict_context": "Disputa sobre horário da natação",
            "child_name": "João",
            "family_unit_id": 1
        }
    )
    assert response.status_code == 200
    assert "suggestion" in response.json()

def test_generate_report(client):
    response = client.post(
        "/reports",
        json={
            "name": "Relatório de Teste",
            "filters": {"date": "today"}
        }
    )
    # 200 if reportlab installed, 503 if missing (which is valid for this env)
    assert response.status_code in [200, 503]
    if response.status_code == 200:
        assert "url" in response.json()
        assert "hash" in response.json()

def test_list_reports(client):
    response = client.get("/reports")
    assert response.status_code == 200
    assert "reports" in response.json()

def test_create_and_list_budgets(client):
    # Create
    response = client.post(
        "/budgets",
        json={
            "description": "Material Escolar 2025",
            "estimated_value": 450.0,
            "family_unit_id": 1
        }
    )
    assert response.status_code == 200
    budget_id = response.json()["budget_id"]

    # List
    response = client.get("/budgets?family_unit_id=1")
    assert response.status_code == 200
    assert len(response.json()["budgets"]) > 0

def test_negotiate_budget(client):
    # Create base budget first
    client.post("/budgets", json={"description": "T2", "estimated_value": 100.0, "family_unit_id": 1})
    
    response = client.post(
        "/budgets/1/negotiate",
        json={
            "comment": "Acho que 400 é suficiente",
            "counter_offer": 400.0
        }
    )
    assert response.status_code == 200

def test_analyze_budget(client):
    response = client.post("/budgets/1/analyze")
    assert response.status_code == 200
    assert "analysis" in response.json()

def test_create_expense(client):
    # Mock file upload
    import io
    file_content = b"fake file content"
    file = io.BytesIO(file_content)
    
    response = client.post(
        "/expenses",
        data={
            "description": "Consulta Dentista",
            "amount": 150.0,
            "child_id": 1,
            "family_unit_id": 1
        },
        files={"file": ("test.pdf", file, "application/pdf")}
    )
    assert response.status_code == 200
    data = response.json()
    assert "expense_id" in data
    assert "file_url" in data
    
    # Test file retrieval (local storage)
    file_url = data["file_url"]
    if file_url.startswith("/expenses"):
        expense_id = data["expense_id"]
        res = client.get(f"/attachments/expenses/{expense_id}")
        assert res.status_code == 200, f"Status: {res.status_code}, Body: {res.text}"
        assert res.content == b"fake file content"
