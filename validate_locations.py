import http.client
import json

def test_locations_validation():
    conn = http.client.HTTPConnection("127.0.0.1", 8000)
    headers = {"Authorization": "Bearer mock_dev_token"}
    
    print("--- Testando Autocomplete ---")
    query = "Avenida Paulista"
    conn.request("GET", f"/locations/autocomplete?query={query.replace(' ', '%20')}", headers=headers)
    resp = conn.getresponse()
    status = resp.status
    data = json.loads(resp.read().decode())
    print(f"Status: {status}")
    if status == 200:
        print(f"Número de predições: {len(data.get('predictions', []))}")
        if data.get('predictions'):
             print(f"Primeiro resultado: {data['predictions'][0]['description']}")
    else:
        print(f"Erro: {data}")

    print("\n--- Testando Criação de Localização ---")
    payload = {
        "name": "Local Teste Validação",
        "type": "Residência",
        "address": "Avenida Paulista, 1000, São Paulo, SP"
    }
    conn.request("POST", "/locations", body=json.dumps(payload), headers={"Content-Type": "application/json", **headers})
    resp = conn.getresponse()
    status = resp.status
    data = json.loads(resp.read().decode())
    print(f"Status: {status}")
    print(f"Resposta: {data}")

    if status == 200:
        print("\n--- Listando Localizações ---")
        conn.request("GET", "/locations", headers=headers)
        resp = conn.getresponse()
        data = json.loads(resp.read().decode())
        print(f"Total de locais encontrados: {len(data.get('locations', []))}")
        for loc in data.get('locations', []):
            if loc['name'] == "Local Teste Validação":
                print(f"✅ Localização '{loc['name']}' encontrada no banco com ID {loc['id']}")
                print(f"📍 Coordenadas salvas: {loc['latitude']}, {loc['longitude']}")

    conn.close()

if __name__ == "__main__":
    test_locations_validation()
