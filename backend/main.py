import os
from dotenv import load_dotenv
# Carregar variáveis de ambiente do arquivo .env na raiz do projeto
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from routers import onboarding, locations, calendar, expenses, budgets, gamification, appointments, reports, chats, agreements, notifications, users, auth
from database import get_db, engine
import models

from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import sentry_sdk

sentry_sdk.init(
    dsn=os.environ.get("SENTRY_DSN", ""),
    traces_sample_rate=1.0,
    _experiments={
        "continuous_profiling_auto_start": True,
    },
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Criar tabelas se não existirem no startup
    models.Base.metadata.create_all(bind=engine)
    # Criar diretórios se não existirem
    os.makedirs("reports", exist_ok=True)
    os.makedirs("expenses", exist_ok=True)
    yield

app = FastAPI(lifespan=lifespan)

app.include_router(auth.router)
app.include_router(onboarding.router)
app.include_router(locations.router)
app.include_router(calendar.router)
app.include_router(expenses.router)
app.include_router(budgets.router)
app.include_router(gamification.router)
app.include_router(appointments.router)
app.include_router(reports.router)
app.include_router(chats.router)
app.include_router(agreements.router)
app.include_router(notifications.router)
app.include_router(users.router)

# Configuração da chave da API do Google Maps (usar variável de ambiente)
if not os.environ.get('GOOGLE_MAPS_API_KEY'):
    os.environ['GOOGLE_MAPS_API_KEY'] = os.getenv('GOOGLE_MAPS_API_KEY', '')

# Configuração do CORS
allowed_origins = [
    "http://localhost",
    "http://localhost:3000",
    "http://localhost:8000",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:8000",
    "http://127.0.0.1:8080",
    "http://0.0.0.0:3000",
    "http://0.0.0.0:8000",
    "https://mediare.com",
    "https://api.mediare.com",
    "https://app.mediare.com"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "System is healthy"}

@app.get("/map", response_class=HTMLResponse)
def get_map():
    maps_key = os.environ.get('GOOGLE_MAPS_API_KEY', '')
    html_content = f"""<!DOCTYPE html>
<html>
  <head>
    <title>Maps and Places Autocomplete</title>
    <script>
      async function init() {{
        await customElements.whenDefined('gmp-map');
        const map = document.querySelector('gmp-map');
        const marker = document.querySelector('gmp-advanced-marker');
        const placePicker = document.querySelector('gmpx-place-picker');
        const infowindow = new google.maps.InfoWindow();

        placePicker.addEventListener('gmpx-placechange', () => {{
          const place = placePicker.value;
          if (!place.location) {{
            window.alert("No details available for input: '" + place.name + "'");
            return;
          }}
          if (place.viewport) {{
            map.innerMap.fitBounds(place.viewport);
          }} else {{
            map.center = place.location;
            map.zoom = 17;
          }}
          marker.position = place.location;
          infowindow.setContent(place.name);
          infowindow.open(map.innerMap, marker);
        }});
      }}
      document.addEventListener('DOMContentLoaded', init);
    </script>
    <script type="module" src="https://unpkg.com/@googlemaps/extended-component-library"></script>
    <style>
      html, body {{ height: 100%; margin: 0; padding: 0; }}
      .container {{ display: flex; flex-direction: column; height: 100%; }}
      .picker {{ padding: 10px; }}
      gmp-map {{ flex: 1; }}
    </style>
  </head>
  <body>
    <div class="container">
      <div class="picker">
        <gmpx-place-picker placeholder="Buscar endereço..."></gmpx-place-picker>
      </div>
      <gmp-map center="-23.55052, -46.633308" zoom="13" map-id="DEMO_MAP_ID">
        <gmp-advanced-marker></gmp-advanced-marker>
      </gmp-map>
    </div>
    <script src="https://maps.googleapis.com/maps/api/js?key={maps_key}&libraries=places&v=beta"></script>
  </body>
</html>
"""
    return HTMLResponse(content=html_content)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
