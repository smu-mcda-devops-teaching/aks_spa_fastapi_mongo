from fastapi import APIRouter, HTTPException
from app.models import Flight
from app.database import db
from bson import ObjectId

router = APIRouter(prefix="/flights", tags=["flights"])

@router.post("/", response_model=Flight)
async def create_flight(flight: Flight):
    result = await db.flights.insert_one(flight.dict(exclude={"id"}))
    flight.id = str(result.inserted_id)
    return flight

@router.get("/{flight_id}", response_model=Flight)
async def get_flight(flight_id: str):
    flight = await db.flights.find_one({"_id": ObjectId(flight_id)})
    if not flight:
        raise HTTPException(status_code=404, detail="Flight not found")
    flight["id"] = str(flight["_id"])
    return flight

@router.put("/{flight_id}", response_model=Flight)
async def update_flight(flight_id: str, flight: Flight):
    await db.flights.update_one({"_id": ObjectId(flight_id)}, {"$set": flight.dict(exclude={"id"})})
    flight.id = flight_id
    return flight

@router.delete("/{flight_id}")
async def delete_flight(flight_id: str):
    result = await db.flights.delete_one({"_id": ObjectId(flight_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Flight not found")
    return {"message": "Flight deleted"}