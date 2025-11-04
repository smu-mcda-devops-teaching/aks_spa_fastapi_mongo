from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime
from enum import Enum


class BookingStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"


class FlightStatus(str, Enum):
    SCHEDULED = "scheduled"
    DELAYED = "delayed"
    BOARDING = "boarding"
    DEPARTED = "departed"
    ARRIVED = "arrived"
    CANCELLED = "cancelled"


class PaymentStatus(str, Enum):
    PENDING = "pending"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"


class UserRole(str, Enum):
    CUSTOMER = "customer"
    ADMIN = "admin"


class User(BaseModel):
    id: Optional[str] = None
    email: EmailStr
    password_hash: str
    first_name: str
    last_name: str
    phone: Optional[str] = None
    role: UserRole = UserRole.CUSTOMER
    created_at: Optional[datetime] = None


class Passenger(BaseModel):
    id: Optional[str] = None
    user_id: str
    first_name: str
    last_name: str
    date_of_birth: datetime
    passport_number: Optional[str] = None
    nationality: str
    created_at: Optional[datetime] = None


class Airline(BaseModel):
    id: Optional[str] = None
    name: str
    code: str = Field(..., min_length=2, max_length=3)
    logo_url: Optional[str] = None
    country: str


class Airport(BaseModel):
    id: Optional[str] = None
    code: str = Field(..., min_length=3, max_length=3)  # IATA code
    name: str
    city: str
    country: str
    timezone: str


class Flight(BaseModel):
    id: Optional[str] = None
    flight_number: str
    airline_id: str
    origin: str  # Airport code
    destination: str  # Airport code
    departure_time: datetime
    arrival_time: datetime
    price: float = Field(gt=0)
    available_seats: int = Field(ge=0)
    total_seats: int = Field(gt=0)
    aircraft_type: Optional[str] = None
    status: FlightStatus = FlightStatus.SCHEDULED


class Booking(BaseModel):
    id: Optional[str] = None
    booking_reference: str
    user_id: str
    flight_id: str
    passenger_ids: List[str]
    seats: int = Field(gt=0)
    total_price: float = Field(gt=0)
    status: BookingStatus = BookingStatus.PENDING
    payment_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class Payment(BaseModel):
    id: Optional[str] = None
    booking_id: str
    amount: float = Field(gt=0)
    payment_method: str
    status: PaymentStatus = PaymentStatus.PENDING
    transaction_id: Optional[str] = None
    created_at: Optional[datetime] = None

class StripePayment(BaseModel):
    payment_method_id: str
    amount: int

class PayPalPayment(BaseModel):
    order_id: str