from fastapi import APIRouter, Query, HTTPException
from app.models import Flight
from app.database import db
from app.utils.flight_search import search_flights_with_connections
from typing import List, Optional, Dict, Any
from datetime import datetime

router = APIRouter(prefix="/search", tags=["search"])


@router.get("/flights")
async def search_flights(
    origin: str,
    destination: str,
    departure_date: Optional[str] = None,
    include_connections: bool = Query(default=True, description="Include connecting flights"),
    max_layover_hours: int = Query(default=6, ge=1, le=24),
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    min_seats: Optional[int] = Query(default=1, ge=1),
    max_results: int = Query(default=50, le=100)
) -> List[Dict[str, Any]]:
    """
    Search for flights including direct and connecting options
    
    Args:
        origin: Origin airport code (e.g., LAX)
        destination: Destination airport code (e.g., DXB)
        departure_date: Departure date in YYYY-MM-DD format
        include_connections: Whether to include connecting flights
        max_layover_hours: Maximum layover time for connections
        min_price: Minimum price filter
        max_price: Maximum price filter
        min_seats: Minimum available seats required
        max_results: Maximum number of results to return
    
    Returns:
        List of flight options (direct and connecting)
    """
    # Parse departure date
    parsed_date = None
    if departure_date:
        try:
            parsed_date = datetime.strptime(departure_date, "%Y-%m-%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    
    # Search for flights
    results = await search_flights_with_connections(
        db=db,
        origin=origin,
        destination=destination,
        departure_date=parsed_date,
        max_layover_hours=max_layover_hours,
        include_connections=include_connections,
        max_results=max_results
    )
    
    # Apply additional filters
    filtered_results = results
    
    if min_price is not None:
        filtered_results = [r for r in filtered_results if r.get("total_price", 0) >= min_price]
    
    if max_price is not None:
        filtered_results = [r for r in filtered_results if r.get("total_price", 0) <= max_price]
    
    # Filter by minimum seats (check all segments for connecting flights)
    if min_seats is not None and min_seats > 1:
        def has_enough_seats(result):
            if result.get("is_direct"):
                return result.get("available_seats", 0) >= min_seats
            else:
                # For connections, all segments must have enough seats
                return all(seg.get("available_seats", 0) >= min_seats for seg in result.get("segments", []))
        
        filtered_results = [r for r in filtered_results if has_enough_seats(r)]
    
    return filtered_results[:max_results]


@router.get("/flights/by-route")
async def search_flights_by_route(origin: str, destination: str):
    """Search flights for a specific route"""
    pass


@router.get("/available-destinations")
async def get_available_destinations(origin: str):
    """Get all available destinations from a given origin"""
    pass


@router.get("/popular-routes")
async def get_popular_routes(limit: int = Query(default=10, le=50)):
    """Get most popular flight routes"""
    pass
