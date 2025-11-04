from fastapi import APIRouter, HTTPException, status
from app.models import Airline
from typing import List

router = APIRouter(prefix="/airlines", tags=["airlines"])


@router.get("/", response_model=List[Airline])
async def get_airlines():
    """Get all airlines"""
    pass


@router.get("/{airline_id}", response_model=Airline)
async def get_airline(airline_id: str):
    """Get airline by ID"""
    pass


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=Airline)
async def create_airline(airline: Airline):
    """Create a new airline (admin only)"""
    pass


@router.put("/{airline_id}", response_model=Airline)
async def update_airline(airline_id: str, airline: Airline):
    """Update airline information (admin only)"""
    pass


@router.delete("/{airline_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_airline(airline_id: str):
    """Delete an airline (admin only)"""
    pass


@router.get("/{airline_id}/flights")
async def get_airline_flights(airline_id: str):
    """Get all flights for a specific airline"""
    pass
