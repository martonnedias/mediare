import os
import sys

# Adiciona o diretório backend ao path para poder importar ai_utils
backend_path = os.path.join(os.getcwd(), "backend")
sys.path.append(backend_path)

try:
    from ai_utils import gemini_client
    
    print("\nTestando integração com GeminiClient...")
    
    # Teste de geração simples
    prompt = "Diga 'Conexão Vertex AI ativa' se você estiver funcionando corretamente."
    res = gemini_client.generate_content(prompt)
    
    if res:
        print(f"Sucesso! Resposta: {res}")
    else:
        print("Falha na geração de conteúdo.")
        
except Exception as e:
    print(f"Erro no teste de integração: {e}")
