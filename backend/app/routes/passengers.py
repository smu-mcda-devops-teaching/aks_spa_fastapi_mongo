from fastapi import APIRouter, HTTPException, status
from app.models import Passenger
from typing import List

router = APIRouter(prefix="/passengers", tags=["passengers"])


@router.get("/", response_model=List[Passenger])
async def get_passengers():
    """Get all passengers"""
    pass


@router.get("/{passenger_id}", response_model=Passenger)
async def get_passenger(passenger_id: str):
    """Get passenger by ID"""
    pass


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=Passenger)
async def create_passenger(passenger: Passenger):
    """Create a new passenger"""
    pass


@router.put("/{passenger_id}", response_model=Passenger)
async def update_passenger(passenger_id: str, passenger: Passenger):
    """Update passenger information"""
    pass


@router.delete("/{passenger_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_passenger(passenger_id: str):
    """Delete a passenger"""
    pass


@router.get("/user/{user_id}", response_model=List[Passenger])
async def get_user_passengers(user_id: str):
    """Get all passengers associated with a user"""
    pass
