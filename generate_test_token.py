from datetime import datetime, timedelta
from jose import jwt

# Configurações do token
SECRET_KEY = "test_secret_key"
ALGORITHM = "HS256"

def generate_test_token():
    expiration = datetime.utcnow() + timedelta(hours=1)
    payload = {
        "sub": "test_user",
        "exp": expiration,
        "family_unit_id": 1
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token

if __name__ == "__main__":
    token = generate_test_token()
    print("Token de teste gerado:", token)