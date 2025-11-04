from motor.motor_asyncio import AsyncIOMotorDatabase
import logging

logger = logging.getLogger(__name__)


async def create_indexes(db: AsyncIOMotorDatabase):
    """Create all necessary indexes for optimal query performance"""
    
    try:
        # Flights collection indexes
        await db.flights.create_index([("origin", 1), ("destination", 1)])
        await db.flights.create_index([("departure_time", 1)])
        await db.flights.create_index([("arrival_time", 1)])
        await db.flights.create_index([("price", 1)])
        await db.flights.create_index([("airline_id", 1)])
        await db.flights.create_index([("status", 1)])
        await db.flights.create_index([("available_seats", 1)])
        await db.flights.create_index([("flight_number", 1)], unique=True)
        
        # Compound index for common flight search queries
        await db.flights.create_index([
            ("origin", 1),
            ("destination", 1),
            ("departure_time", 1),
            ("available_seats", 1)
        ])
        
        # Compound index for price range searches
        await db.flights.create_index([
            ("origin", 1),
            ("destination", 1),
            ("price", 1)
        ])
        
        logger.info("Flight indexes created successfully")
        
        # Bookings collection indexes
        await db.bookings.create_index([("user_id", 1)])
        await db.bookings.create_index([("flight_id", 1)])
        await db.bookings.create_index([("booking_reference", 1)], unique=True)
        await db.bookings.create_index([("status", 1)])
        await db.bookings.create_index([("created_at", -1)])  # Descending for recent bookings
        
        # Compound index for user bookings by status
        await db.bookings.create_index([
            ("user_id", 1),
            ("status", 1),
            ("created_at", -1)
        ])
        
        logger.info("Booking indexes created successfully")
        
        # Users collection indexes
        await db.users.create_index([("email", 1)], unique=True)
        await db.users.create_index([("role", 1)])
        await db.users.create_index([("created_at", -1)])
        
        logger.info("User indexes created successfully")
        
        # Passengers collection indexes
        await db.passengers.create_index([("user_id", 1)])
        await db.passengers.create_index([("passport_number", 1)])
        
        logger.info("Passenger indexes created successfully")
        
        # Payments collection indexes
        await db.payments.create_index([("booking_id", 1)])
        await db.payments.create_index([("status", 1)])
        await db.payments.create_index([("transaction_id", 1)])
        await db.payments.create_index([("created_at", -1)])
        
        logger.info("Payment indexes created successfully")
        
        # Airlines collection indexes
        await db.airlines.create_index([("code", 1)], unique=True)
        await db.airlines.create_index([("name", 1)])
        await db.airlines.create_index([("country", 1)])
        
        logger.info("Airline indexes created successfully")
        
        # Airports collection indexes
        await db.airports.create_index([("code", 1)], unique=True)
        await db.airports.create_index([("name", 1)])
        await db.airports.create_index([("city", 1)])
        await db.airports.create_index([("country", 1)])
        
        # Text index for airport search
        await db.airports.create_index([
            ("name", "text"),
            ("city", "text"),
            ("code", "text")
        ])
        
        logger.info("Airport indexes created successfully")
        logger.info("All indexes created successfully")
        
    except Exception as e:
        logger.error(f"Error creating indexes: {str(e)}")
        raise
