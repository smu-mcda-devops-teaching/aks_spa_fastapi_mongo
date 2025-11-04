from fastapi import APIRouter, HTTPException, status
from app.models import User, UserRole
from typing import List

router = APIRouter(prefix="/users", tags=["users"])


@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_user(user: User):
    """Register a new user"""
    # TODO: Hash password before storing
    # TODO: Check if user already exists
    pass


@router.post("/login")
async def login_user(email: str, password: str):
    """Authenticate user and return token"""
    # TODO: Verify credentials
    # TODO: Generate JWT token
    pass


@router.get("/", response_model=List[User])
async def get_users():
    """Get all users (admin only)"""
    pass


@router.get("/{user_id}", response_model=User)
async def get_user(user_id: str):
    """Get user by ID"""
    pass


@router.put("/{user_id}", response_model=User)
async def update_user(user_id: str, user: User):
    """Update user information"""
    pass


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: str):
    """Delete user account"""
    pass


@router.get("/{user_id}/bookings")
async def get_user_bookings(user_id: str):
    """Get all bookings for a user"""
    pass
