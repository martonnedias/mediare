import pytest
from models import User, FamilyUnit, FamilyMember, Budget
import random
from datetime import datetime, timezone

def test_multi_tenant_isolation_budgets_v4(client, db_session):
    suffix = str(random.randint(10000, 99999))
    
    # 1. Family 1 (Owner)
    owner = User(
        email=f"owner_{suffix}@test.com", 
        full_name="Owner", 
        cpf=f"123{suffix}",
        hashed_password="hash",
        onboarding_completed=True
    )
    db_session.add(owner)
    db_session.commit()
    db_session.refresh(owner)
    
    f1 = FamilyUnit(name=f"Family1_{suffix}", mode="collaborative")
    db_session.add(f1)
    db_session.commit()
    db_session.refresh(f1)
    
    m1 = FamilyMember(user_id=owner.id, family_id=f1.id, role="parent")
    db_session.add(m1)
    db_session.commit()
    
    # 2. Family 2 (Secret)
    f2 = FamilyUnit(name=f"Secret_{suffix}", mode="collaborative")
    db_session.add(f2)
    db_session.commit()
    db_session.refresh(f2)
    
    budget2 = Budget(
        description=f"SECRET_{suffix}", 
        estimated_value=500.0, 
        family_unit_id=f2.id,
        created_at=datetime.now(timezone.utc)
    )
    db_session.add(budget2)
    db_session.commit()

    # 3. Setup Auth Override using the SAME app object as TestClient
    from main import app
    from routers.auth import verify_token
    
    app.dependency_overrides[verify_token] = lambda: owner

    try:
        # 4. Success Case
        response = client.get(f"/budgets?family_unit_id={f1.id}")
        assert response.status_code == 200

        # 5. Security Case
        response = client.get(f"/budgets?family_unit_id={f2.id}")
        
        # Now that we fixed the vulnerability, this should return 403 Forbidden
        # Or if we just filter results, it should return 200 but with empty list.
        # However, check_family_access raises 403.
        
        if response.status_code == 403:
            print("\n[SECURITY] OK: Blocked unauthorized access with 403")
        elif response.status_code == 200:
            data = response.json()
            budgets = data.get("budgets", [])
            has_leak = any(b["description"] == f"SECRET_{suffix}" for b in budgets)
            if has_leak:
                print(f"\n[SECURITY] VULNERABILITY CONFIRMED: Leak in /budgets")
                pytest.fail("Security Vulnerability: data leakage between families")
            else:
                print("\n[SECURITY] OK: Result set filtered")
        else:
            pytest.fail(f"Unexpected status code: {response.status_code}, detail: {response.text}")
            
    finally:
        app.dependency_overrides.pop(verify_token, None)
