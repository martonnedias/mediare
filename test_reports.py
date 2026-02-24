import sys
import os

# Adiciona o diretório backend ao path para facilitar imports
backend_path = os.path.join(os.getcwd(), "backend")
sys.path.append(backend_path)

from fastapi.testclient import TestClient
from main import app
from routers.auth import verify_token

# Mock the current user
class MockUser:
    def __init__(self):
        self.id = 1
        self.firebase_uid = "mock123"
        self.full_name = "User Teste"
        self.family_unit_id = 1

def mock_verify_token():
    return MockUser()

app.dependency_overrides[verify_token] = mock_verify_token

client = TestClient(app)

def test_generate_report():
    print("\n[+] Testing POST /reports")
    response = client.post(
        "/reports",
        json={
            "name": "Dossier de Teste IA",
            "filters": {
                "include_events": True,
                "include_expenses": True
            }
        }
    )
    
    print("Status Code:", response.status_code)
    try:
        data = response.json()
        print("Response JSON:", data)
    except Exception as e:
        print("Response Text:", response.text)
        return
        
    assert response.status_code == 200, f"Failed to generate report: {response.text}"
    assert "url" in data, "No URL in response"
    print("✅ Successfully generated report!")
    
    # Test downloading the report
    report_id = data.get("report_id")
    print(f"\n[+] Testing GET /attachments/reports/{report_id}")
    download_res = client.get(f"/items/reports/{report_id}") # Wait, the route says /attachments/reports/{report_id}
    # Need to see if it's /attachments/reports or /reports/attachments/reports?
    # Ah, the route in reports.py is @router.get("/attachments/reports/{report_id}")
    # but the router is included without a prefix! let's check `backend/main.py`.
    # main.py includes `app.include_router(reports.router)`, with no prefix. So the route is exactly `/attachments/reports/{report_id}`.
    download_res = client.get(f"/attachments/reports/{report_id}")
    print("Download Status Code:", download_res.status_code)
    print("Content-Type:", download_res.headers.get("content-type"))
    assert download_res.status_code == 200, f"Failed to download report: {download_res.text}"
    print("✅ Successfully downloaded report!")

if __name__ == "__main__":
    test_generate_report()
