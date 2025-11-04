from fastapi import FastAPI
from contextlib import asynccontextmanager
from app.routes import (
    flights,
    bookings,
    users,
    passengers,
    payments,
    search,
    airlines,
    airports
)
from app.database import db
from app.indexes import create_indexes
import logging

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize app on startup and cleanup on shutdown"""
    # Startup
    logger.info("Creating database indexes...")
    await create_indexes(db)
    logger.info("Application startup complete")
    yield
    # Shutdown
    logger.info("Application shutdown")


app = FastAPI(title="Flight Booking API", lifespan=lifespan)

# Include all routers
app.include_router(users.router)
app.include_router(flights.router)
app.include_router(bookings.router)
app.include_router(passengers.router)
app.include_router(payments.router)
app.include_router(search.router)
app.include_router(airlines.router)
app.include_router(airports.router)
