from fastapi import APIRouter, HTTPException, status
from app.models import Airport
from typing import List

router = APIRouter(prefix="/airports", tags=["airports"])


@router.get("/", response_model=List[Airport])
async def get_airports():
    """Get all airports"""
    pass


@router.get("/{airport_id}", response_model=Airport)
async def get_airport(airport_id: str):
    """Get airport by ID"""
    pass


@router.get("/code/{code}", response_model=Airport)
async def get_airport_by_code(code: str):
    """Get airport by IATA code"""
    pass


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=Airport)
async def create_airport(airport: Airport):
    """Create a new airport (admin only)"""
    pass


@router.put("/{airport_id}", response_model=Airport)
async def update_airport(airport_id: str, airport: Airport):
    """Update airport information (admin only)"""
    pass


@router.delete("/{airport_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_airport(airport_id: str):
    """Delete an airport (admin only)"""
    pass


@router.get("/search/{query}")
async def search_airports(query: str):
    """Search airports by name, city, or code"""
    pass
