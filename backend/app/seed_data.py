import asyncio
import random
from datetime import datetime, timedelta
from motor.motor_asyncio import AsyncIOMotorClient
from faker import Faker
import os
from typing import List
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

fake = Faker()

# Real airport data
AIRPORTS = [
    {"code": "JFK", "name": "John F. Kennedy International Airport", "city": "New York", "country": "United States", "timezone": "America/New_York"},
    {"code": "LAX", "name": "Los Angeles International Airport", "city": "Los Angeles", "country": "United States", "timezone": "America/Los_Angeles"},
    {"code": "ORD", "name": "O'Hare International Airport", "city": "Chicago", "country": "United States", "timezone": "America/Chicago"},
    {"code": "DFW", "name": "Dallas/Fort Worth International Airport", "city": "Dallas", "country": "United States", "timezone": "America/Chicago"},
    {"code": "DEN", "name": "Denver International Airport", "city": "Denver", "country": "United States", "timezone": "America/Denver"},
    {"code": "SFO", "name": "San Francisco International Airport", "city": "San Francisco", "country": "United States", "timezone": "America/Los_Angeles"},
    {"code": "SEA", "name": "Seattle-Tacoma International Airport", "city": "Seattle", "country": "United States", "timezone": "America/Los_Angeles"},
    {"code": "LAS", "name": "Harry Reid International Airport", "city": "Las Vegas", "country": "United States", "timezone": "America/Los_Angeles"},
    {"code": "MIA", "name": "Miami International Airport", "city": "Miami", "country": "United States", "timezone": "America/New_York"},
    {"code": "ATL", "name": "Hartsfield-Jackson Atlanta International Airport", "city": "Atlanta", "country": "United States", "timezone": "America/New_York"},
    {"code": "LHR", "name": "London Heathrow Airport", "city": "London", "country": "United Kingdom", "timezone": "Europe/London"},
    {"code": "CDG", "name": "Charles de Gaulle Airport", "city": "Paris", "country": "France", "timezone": "Europe/Paris"},
    {"code": "FRA", "name": "Frankfurt Airport", "city": "Frankfurt", "country": "Germany", "timezone": "Europe/Berlin"},
    {"code": "AMS", "name": "Amsterdam Airport Schiphol", "city": "Amsterdam", "country": "Netherlands", "timezone": "Europe/Amsterdam"},
    {"code": "DXB", "name": "Dubai International Airport", "city": "Dubai", "country": "UAE", "timezone": "Asia/Dubai"},
    {"code": "SIN", "name": "Singapore Changi Airport", "city": "Singapore", "country": "Singapore", "timezone": "Asia/Singapore"},
    {"code": "HKG", "name": "Hong Kong International Airport", "city": "Hong Kong", "country": "Hong Kong", "timezone": "Asia/Hong_Kong"},
    {"code": "NRT", "name": "Narita International Airport", "city": "Tokyo", "country": "Japan", "timezone": "Asia/Tokyo"},
    {"code": "ICN", "name": "Incheon International Airport", "city": "Seoul", "country": "South Korea", "timezone": "Asia/Seoul"},
    {"code": "SYD", "name": "Sydney Airport", "city": "Sydney", "country": "Australia", "timezone": "Australia/Sydney"},
    {"code": "MEL", "name": "Melbourne Airport", "city": "Melbourne", "country": "Australia", "timezone": "Australia/Melbourne"},
    {"code": "YYZ", "name": "Toronto Pearson International Airport", "city": "Toronto", "country": "Canada", "timezone": "America/Toronto"},
    {"code": "YVR", "name": "Vancouver International Airport", "city": "Vancouver", "country": "Canada", "timezone": "America/Vancouver"},
    {"code": "YUL", "name": "Montréal-Pierre Elliott Trudeau International Airport", "city": "Montreal", "country": "Canada", "timezone": "America/Toronto"},
    {"code": "YYC", "name": "Calgary International Airport", "city": "Calgary", "country": "Canada", "timezone": "America/Edmonton"},
    {"code": "YEG", "name": "Edmonton International Airport", "city": "Edmonton", "country": "Canada", "timezone": "America/Edmonton"},
    {"code": "YOW", "name": "Ottawa Macdonald-Cartier International Airport", "city": "Ottawa", "country": "Canada", "timezone": "America/Toronto"},
    {"code": "YWG", "name": "Winnipeg James Armstrong Richardson International Airport", "city": "Winnipeg", "country": "Canada", "timezone": "America/Winnipeg"},
    {"code": "YHZ", "name": "Halifax Stanfield International Airport", "city": "Halifax", "country": "Canada", "timezone": "America/Halifax"},
    {"code": "GRU", "name": "São Paulo/Guarulhos International Airport", "city": "São Paulo", "country": "Brazil", "timezone": "America/Sao_Paulo"},
    {"code": "MEX", "name": "Mexico City International Airport", "city": "Mexico City", "country": "Mexico", "timezone": "America/Mexico_City"},
]

# Real airline data
AIRLINES = [
    {"name": "American Airlines", "code": "AA", "country": "United States"},
    {"name": "Delta Air Lines", "code": "DL", "country": "United States"},
    {"name": "United Airlines", "code": "UA", "country": "United States"},
    {"name": "Southwest Airlines", "code": "WN", "country": "United States"},
    {"name": "British Airways", "code": "BA", "country": "United Kingdom"},
    {"name": "Lufthansa", "code": "LH", "country": "Germany"},
    {"name": "Air France", "code": "AF", "country": "France"},
    {"name": "Emirates", "code": "EK", "country": "UAE"},
    {"name": "Singapore Airlines", "code": "SQ", "country": "Singapore"},
    {"name": "Cathay Pacific", "code": "CX", "country": "Hong Kong"},
    {"name": "Qantas", "code": "QF", "country": "Australia"},
    {"name": "Air Canada", "code": "AC", "country": "Canada"},
]

AIRCRAFT_TYPES = [
    "Boeing 737", "Boeing 777", "Boeing 787", "Airbus A320", 
    "Airbus A350", "Airbus A380", "Boeing 747", "Airbus A330"
]

STATUSES = ["scheduled", "delayed", "boarding", "departed", "arrived", "cancelled"]


async def seed_database(num_flights: int = 10000):
    """
    Seed the database with mock data
    
    Args:
        num_flights: Number of flights to generate
    """
    MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    client = AsyncIOMotorClient(MONGO_URI)
    db = client["flight_booking"]
    
    logger.info(f"Starting database seeding with {num_flights} flights...")
    
    # Clear existing data
    logger.info("Clearing existing data...")
    await db.airports.delete_many({})
    await db.airlines.delete_many({})
    await db.flights.delete_many({})
    
    # Insert airports
    logger.info(f"Inserting {len(AIRPORTS)} airports...")
    airport_result = await db.airports.insert_many(AIRPORTS)
    airport_ids = airport_result.inserted_ids
    logger.info(f"Inserted {len(airport_ids)} airports")
    
    # Insert airlines
    logger.info(f"Inserting {len(AIRLINES)} airlines...")
    airline_result = await db.airlines.insert_many(AIRLINES)
    airline_ids = airline_result.inserted_ids
    logger.info(f"Inserted {len(airline_ids)} airlines")
    
    # Generate flights
    logger.info(f"Generating {num_flights} flights...")
    flights = []
    batch_size = 1000
    
    for i in range(num_flights):
        # Random origin and destination (ensure they're different)
        origin_airport = random.choice(AIRPORTS)
        destination_airport = random.choice([a for a in AIRPORTS if a["code"] != origin_airport["code"]])
        
        airline = random.choice(AIRLINES)
        
        # Generate departure time (next 90 days)
        departure_time = datetime.now() + timedelta(
            days=random.randint(0, 90),
            hours=random.randint(0, 23),
            minutes=random.choice([0, 15, 30, 45])
        )
        
        # Calculate flight duration based on rough distance categories
        duration_hours = random.randint(1, 16)
        arrival_time = departure_time + timedelta(hours=duration_hours, minutes=random.randint(0, 59))
        
        # Generate flight number
        flight_number = f"{airline['code']}{random.randint(100, 9999)}"
        
        # Generate pricing (longer flights = more expensive)
        base_price = 100 + (duration_hours * 50) + random.randint(-50, 150)
        
        # Seat availability
        total_seats = random.choice([150, 180, 200, 250, 300, 350])
        available_seats = random.randint(0, total_seats)
        
        flight = {
            "flight_number": flight_number,
            "airline_id": str(random.choice(airline_ids)),
            "origin": origin_airport["code"],
            "destination": destination_airport["code"],
            "departure_time": departure_time,
            "arrival_time": arrival_time,
            "price": round(base_price, 2),
            "available_seats": available_seats,
            "total_seats": total_seats,
            "aircraft_type": random.choice(AIRCRAFT_TYPES),
            "status": random.choices(
                STATUSES,
                weights=[70, 10, 5, 5, 5, 5],  # Most flights are scheduled
                k=1
            )[0]
        }
        
        flights.append(flight)
        
        # Insert in batches
        if len(flights) >= batch_size:
            await db.flights.insert_many(flights)
            logger.info(f"Inserted batch of {len(flights)} flights ({i+1}/{num_flights} total)")
            flights = []
    
    # Insert remaining flights
    if flights:
        await db.flights.insert_many(flights)
        logger.info(f"Inserted final batch of {len(flights)} flights")
    
    # Generate some statistics
    total_flights = await db.flights.count_documents({})
    total_airports = await db.airports.count_documents({})
    total_airlines = await db.airlines.count_documents({})
    
    logger.info("=" * 50)
    logger.info("Database seeding completed!")
    logger.info(f"Total Airports: {total_airports}")
    logger.info(f"Total Airlines: {total_airlines}")
    logger.info(f"Total Flights: {total_flights}")
    logger.info("=" * 50)
    
    client.close()


if __name__ == "__main__":
    import sys
    
    # Get number of flights from command line argument, default to 10000
    num_flights = int(sys.argv[1]) if len(sys.argv) > 1 else 10000
    
    asyncio.run(seed_database(num_flights))
