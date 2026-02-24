import os
from googlemaps import Client

GOOGLE_MAPS_API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY", "")
gmaps = Client(key=GOOGLE_MAPS_API_KEY)


try:
    # Teste simples
    result = gmaps.geocode("1600 Amphitheatre Parkway, Mountain View, CA")
    print("Chave válida. Resultado do teste:", result)
except Exception as e:
    print("Erro ao testar a chave do Google Maps:", e)