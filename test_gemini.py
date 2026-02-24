import os
from google import genai

# Carrega a chave da variável de ambiente
api_key = os.environ.get("GOOGLE_API_KEY")

if not api_key:
    print("ERRO: Variável de ambiente GOOGLE_API_KEY não encontrada.")
else:
    print(f"Chave encontrada iniciada em: {api_key[:8]}...")
    
    try:
        # Configura o SDK v1 (google-genai)
        client = genai.Client(api_key=api_key)
        
        # Tentando 2.5
        model_id = "gemini-2.5-flash"
        print(f"\nTentando inicializar o modelo: {model_id}")
        
        print("Enviando solicitação 'Hello World'...")
        response = client.models.generate_content(
            model=model_id,
            contents="Diga 'Olá Mundo' e confirme que você é o modelo Gemini."
        )
        
        print("\n--- RESPOSTA DA API ---")
        print(response.text)
        print("-----------------------")
        print("\nTeste concluído com sucesso!")
            
    except Exception as e:
        print(f"\nErro ao testar a API: {e}")
