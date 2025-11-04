from fastapi import APIRouter, HTTPException
from app.models import Booking
from app.database import db
from bson import ObjectId

router = APIRouter(prefix="/bookings", tags=["bookings"])

@router.post("/", response_model=Booking)
async def create_booking(booking: Booking):
    result = await db.bookings.insert_one(booking.dict(exclude={"id"}))
    booking.id = str(result.inserted_id)
    return booking

@router.get("/{booking_id}", response_model=Booking)
async def get_booking(booking_id: str):
    booking = await db.bookings.find_one({"_id": ObjectId(booking_id)})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    booking["id"] = str(booking["_id"])
    return booking

@router.put("/{booking_id}", response_model=Booking)
async def update_booking(booking_id: str, booking: Booking):
    await db.bookings.update_one({"_id": ObjectId(booking_id)}, {"$set": booking.dict(exclude={"id"})})
    booking.id = booking_id
    return booking

@router.delete("/{booking_id}")
async def delete_booking(booking_id: str):
    result = await db.bookings.delete_one({"_id": ObjectId(booking_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Booking not found")
    return {"message": "Booking deleted"}