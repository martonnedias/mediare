from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
import requests
from .auth import verify_token, check_family_access
from database import get_db
from models import Location, LocationUsageHistory
from googlemaps import Client

router = APIRouter()

# Google Maps API Client
import os
GOOGLE_MAPS_API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY", "")

if GOOGLE_MAPS_API_KEY:
    gmaps = Client(key=GOOGLE_MAPS_API_KEY)
else:
    gmaps = None
    print("WARNING: Google Maps Client not initialized due to missing API Key")

class LocationRequest(BaseModel):
    name: str
    type: str
    address: str

@router.get("/locations/autocomplete")
def autocomplete_location(query: str, user = Depends(verify_token)):
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(status_code=503, detail="Google Maps API key missing")
    
    url = "https://places.googleapis.com/v1/places:autocomplete"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_MAPS_API_KEY
    }
    payload = {
        "input": query,
        "languageCode": "pt-BR"
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        data = response.json()
        
        results = []
        for suggestion in data.get("suggestions", []):
            pred = suggestion.get("placePrediction", {})
            results.append({
                "description": pred.get("text", {}).get("text"),
                "place_id": pred.get("placeId"),
                "main_text": pred.get("structuredFormat", {}).get("mainText", {}).get("text", ""),
                "secondary_text": pred.get("structuredFormat", {}).get("secondaryText", {}).get("text", "")
            })
            
        return {"predictions": results}
    except Exception as e:
        print(f"ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/locations/place-details")
def get_place_details(place_id: str, user = Depends(verify_token)):
    if not GOOGLE_MAPS_API_KEY:
        raise HTTPException(status_code=503, detail="Google Maps API key missing")
    
    url = f"https://places.googleapis.com/v1/places/{place_id}"
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_MAPS_API_KEY,
        "X-Goog-FieldMask": "id,name,displayName,formattedAddress,location,types"
    }
    
    try:
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        result = response.json()
        
        google_types = result.get("types", [])
        suggested_type = "Outro"
        
        type_mapping = {
            "school": "Escola",
            "hospital": "Hospital",
            "doctor": "Clínica",
            "health": "Saúde",
            "park": "Parque",
            "shopping_mall": "Clube",
            "restaurant": "Restaurante",
            "establishment": "Estabelecimento"
        }
        
        for gt in google_types:
            if gt in type_mapping:
                suggested_type = type_mapping[gt]
                break
                
        return {
            "name": result.get("displayName", {}).get("text"),
            "address": result.get("formattedAddress"),
            "latitude": result.get("location", {}).get("latitude"),
            "longitude": result.get("location", {}).get("longitude"),
            "suggested_type": suggested_type
        }
    except Exception as e:
        print(f"ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/locations")
def create_location(request: LocationRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    if user.family_unit_id:
        check_family_access(db, user.id, user.family_unit_id)
    
    if not gmaps:
        raise HTTPException(status_code=503, detail="Google Maps service unavailable")
        
    # Geocode address
    geocode_result = gmaps.geocode(request.address)
    if not geocode_result:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid address")

    location_data = geocode_result[0]['geometry']['location']
    latitude = location_data['lat']
    longitude = location_data['lng']

    location = Location(
        name=request.name,
        type=request.type,
        address=request.address,
        latitude=latitude,
        longitude=longitude,
        family_unit_id=user.family_unit_id
    )
    db.add(location)
    db.commit()
    db.refresh(location)
    return {"message": "Location created successfully", "location": location.id}

@router.get("/locations")
def list_locations(db: Session = Depends(get_db), user = Depends(verify_token)):
    # Security Check
    if user.family_unit_id:
        check_family_access(db, user.id, user.family_unit_id)
        
    locations = db.query(Location).filter(Location.family_unit_id == user.family_unit_id).all()
    return {"locations": locations}

@router.get("/locations/types")
def get_location_types():
    return {
        "types": [
            "Casa do Pai", "Casa da Mãe", "Escola", "Natação", 
            "Futebol", "Balé", "Curso de Idiomas", "Clínica Médica", 
            "Hospital", "Parque", "Shopping", "Outro"
        ]
    }

@router.put("/locations/{location_id}")
def update_location(location_id: int, request: LocationRequest, db: Session = Depends(get_db), user = Depends(verify_token)):
    location = db.query(Location).filter(Location.id == location_id, Location.family_unit_id == user.family_unit_id).first()
    if not location:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")

    # Update location details
    if not gmaps:
        raise HTTPException(status_code=503, detail="Google Maps service unavailable")

    geocode_result = gmaps.geocode(request.address)
    if not geocode_result:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid address")

    location_data = geocode_result[0]['geometry']['location']
    location.name = request.name
    location.type = request.type
    location.address = request.address
    location.latitude = location_data['lat']
    location.longitude = location_data['lng']
    db.commit()
    return {"message": "Location updated successfully"}

@router.delete("/locations/{location_id}")
def delete_location(location_id: int, db: Session = Depends(get_db), user = Depends(verify_token)):
    location = db.query(Location).filter(Location.id == location_id, Location.family_unit_id == user.family_unit_id).first()
    if not location:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Location not found")

    db.delete(location)
    db.commit()
    return {"message": "Location deleted successfully"}