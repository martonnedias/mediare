import os
from dotenv import load_dotenv
import googlemaps

# Carregar do arquivo .env
load_dotenv(os.path.join(os.path.dirname(__file__), ".env"))

def test_geocoding():
    api_key = os.getenv("GOOGLE_MAPS_API_KEY")
    if not api_key or "YOUR_" in api_key:
        print("❌ ERRO: Chave GOOGLE_MAPS_API_KEY não encontrada no arquivo .env")
        return

    print(f"🔄 Testando Geocodificação com a chave: {api_key[:10]}...")
    
    try:
        gmaps = googlemaps.Client(key=api_key)
        # Tenta geocodificar um endereço genérico
        result = gmaps.geocode("Avenida Paulista, 1000, São Paulo, SP")
        
        if result:
            location = result[0]['geometry']['location']
            print("✅ SUCESSO! A API de Geocodificação respondeu corretamente.")
            print(f"📍 Coordenadas de teste: Lat {location['lat']}, Lng {location['lng']}")
        else:
            print("❌ ERRO: A API retornou uma lista vazia. Verifique se o endereço é válido e se a cota está ativa.")
            
    except Exception as e:
        print(f"❌ ERRO na integração: {e}")
        if "API keys with referer restrictions" in str(e):
            print("💡 DICA: Sua chave tem restrições de URL. Remova-as no Google Console para usar no Backend.")
        elif "REQUEST_DENIED" in str(e):
            print("💡 DICA: Certifique-se de que a 'Geocoding API' está ATIVADA no Google Cloud Console.")

if __name__ == "__main__":
    test_geocoding()
