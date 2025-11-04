from motor.motor_asyncio import AsyncIOMotorDatabase
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import logging

logger = logging.getLogger(__name__)


async def search_flights_with_connections(
    db: AsyncIOMotorDatabase,
    origin: str,
    destination: str,
    departure_date: Optional[datetime] = None,
    max_layover_hours: int = 6,
    min_layover_hours: float = 1.5,
    include_connections: bool = True,
    max_results: int = 50
) -> List[Dict]:
    """
    Search for direct and connecting flights between two airports
    
    Args:
        db: Database instance
        origin: Origin airport code
        destination: Destination airport code
        departure_date: Desired departure date (optional)
        max_layover_hours: Maximum layover time in hours
        min_layover_hours: Minimum layover time in hours
        include_connections: Whether to include connecting flights
        max_results: Maximum number of results to return
    
    Returns:
        List of flight options (direct and connecting)
    """
    results = []
    
    # Build base query
    base_query = {
        "origin": origin.upper(),
        "destination": destination.upper(),
        "status": {"$nin": ["cancelled"]},
        "available_seats": {"$gt": 0}
    }
    
    # Add date filter if provided
    if departure_date:
        start_of_day = departure_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_of_day = start_of_day + timedelta(days=1)
        base_query["departure_time"] = {"$gte": start_of_day, "$lt": end_of_day}
    
    # 1. Find direct flights
    logger.info(f"Searching for direct flights from {origin} to {destination}")
    direct_flights = await db.flights.find(base_query).to_list(length=max_results)
    
    for flight in direct_flights:
        flight["_id"] = str(flight["_id"])
        flight["is_direct"] = True
        flight["total_duration"] = (flight["arrival_time"] - flight["departure_time"]).total_seconds() / 60
        flight["total_price"] = flight["price"]
        flight["segments"] = [flight]
        results.append(flight)
    
    logger.info(f"Found {len(direct_flights)} direct flights")
    
    # 2. Find connecting flights (1 stop)
    if include_connections:
        logger.info(f"Searching for connecting flights from {origin} to {destination}")
        
        # Build aggregation pipeline
        pipeline = [
            # Stage 1: Find first leg flights from origin
            {
                "$match": {
                    "origin": origin.upper(),
                    "destination": {"$ne": destination.upper()},
                    "status": {"$nin": ["cancelled"]},
                    "available_seats": {"$gt": 0}
                }
            },
            # Stage 2: Add date filter if provided
            *([{"$match": {"departure_time": base_query["departure_time"]}}] if departure_date else []),
            # Stage 3: Lookup connecting flights
            {
                "$lookup": {
                    "from": "flights",
                    "let": {
                        "first_destination": "$destination",
                        "first_arrival": "$arrival_time",
                        "first_flight_id": "$_id"
                    },
                    "pipeline": [
                        {
                            "$match": {
                                "$expr": {
                                    "$and": [
                                        {"$eq": ["$origin", "$$first_destination"]},
                                        {"$eq": ["$destination", destination.upper()]},
                                        {"$ne": ["$_id", "$$first_flight_id"]},
                                        # Departure must be after first flight arrival
                                        {"$gte": ["$departure_time", "$$first_arrival"]},
                                        # But not too long after (max layover)
                                        {
                                            "$lte": [
                                                "$departure_time",
                                                {"$add": ["$$first_arrival", max_layover_hours * 3600000]}
                                            ]
                                        },
                                        # And not too short (min layover)
                                        {
                                            "$gte": [
                                                "$departure_time",
                                                {"$add": ["$$first_arrival", min_layover_hours * 3600000]}
                                            ]
                                        }
                                    ]
                                },
                                "status": {"$nin": ["cancelled"]},
                                "available_seats": {"$gt": 0}
                            }
                        }
                    ],
                    "as": "connecting_flights"
                }
            },
            # Stage 4: Unwind connecting flights
            {"$unwind": "$connecting_flights"},
            # Stage 5: Project final structure
            {
                "$project": {
                    "first_flight": "$$ROOT",
                    "second_flight": "$connecting_flights",
                    "layover_airport": "$destination",
                    "total_price": {"$add": ["$price", "$connecting_flights.price"]},
                    "total_duration": {
                        "$divide": [
                            {"$subtract": ["$connecting_flights.arrival_time", "$departure_time"]},
                            60000  # Convert milliseconds to minutes
                        ]
                    },
                    "layover_duration": {
                        "$divide": [
                            {"$subtract": ["$connecting_flights.departure_time", "$arrival_time"]},
                            60000
                        ]
                    }
                }
            },
            # Stage 6: Sort by total price
            {"$sort": {"total_price": 1}},
            # Stage 7: Limit results
            {"$limit": max_results}
        ]
        
        connecting_flights = await db.flights.aggregate(pipeline).to_list(length=max_results)
        
        logger.info(f"Found {len(connecting_flights)} connecting flight options")
        
        # Format connecting flights
        for conn in connecting_flights:
            first_flight = conn["first_flight"]
            second_flight = conn["second_flight"]
            
            # Clean up _id fields
            first_flight["_id"] = str(first_flight["_id"])
            second_flight["_id"] = str(second_flight["_id"])
            first_flight.pop("connecting_flights", None)
            
            connection_option = {
                "_id": f"{first_flight['_id']}-{second_flight['_id']}",
                "is_direct": False,
                "origin": origin.upper(),
                "destination": destination.upper(),
                "departure_time": first_flight["departure_time"],
                "arrival_time": second_flight["arrival_time"],
                "total_price": conn["total_price"],
                "total_duration": conn["total_duration"],
                "segments": [first_flight, second_flight],
                "layover": {
                    "airport": conn["layover_airport"],
                    "duration": conn["layover_duration"]
                },
                "stops": 1
            }
            
            results.append(connection_option)
    
    # Sort all results by price
    results.sort(key=lambda x: (not x.get("is_direct", False), x.get("total_price", 0)))
    
    logger.info(f"Returning {len(results)} total flight options")
    
    return results[:max_results]


async def search_multi_city_flights(
    db: AsyncIOMotorDatabase,
    routes: List[tuple],  # [(origin1, dest1, date1), (origin2, dest2, date2), ...]
) -> List[Dict]:
    """
    Search for multi-city flights
    
    Args:
        db: Database instance
        routes: List of route tuples (origin, destination, date)
    
    Returns:
        List of flight combinations
    """
    # TODO: Implement multi-city search
    pass
