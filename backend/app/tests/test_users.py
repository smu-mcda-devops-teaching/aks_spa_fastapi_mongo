import pytest
from fastapi.testclient import TestClient


class TestUsers:
    """Test suite for users routes"""

    def test_register_user(self, client: TestClient):
        """Test user registration"""
        user_data = {
            "email": "test@example.com",
            "password_hash": "hashed_password",
            "first_name": "John",
            "last_name": "Doe",
            "phone": "+1234567890",
            "role": "customer"
        }
        response = client.post("/users/register", json=user_data)
        assert response.status_code == 201

    def test_login_user(self, client: TestClient):
        """Test user login"""
        response = client.post("/users/login?email=test@example.com&password=password123")
        assert response.status_code in [200, 401]

    def test_get_users(self, client: TestClient):
        """Test getting all users"""
        response = client.get("/users/")
        assert response.status_code in [200, 403]

    def test_get_user(self, client: TestClient):
        """Test getting a specific user"""
        user_id = "test_user_id"
        response = client.get(f"/users/{user_id}")
        assert response.status_code in [200, 404]

    def test_update_user(self, client: TestClient):
        """Test updating user information"""
        user_id = "test_user_id"
        update_data = {
            "email": "newemail@example.com",
            "password_hash": "hashed_password",
            "first_name": "Jane",
            "last_name": "Doe"
        }
        response = client.put(f"/users/{user_id}", json=update_data)
        assert response.status_code in [200, 404]

    def test_delete_user(self, client: TestClient):
        """Test deleting a user"""
        user_id = "test_user_id"
        response = client.delete(f"/users/{user_id}")
        assert response.status_code in [204, 404]

    def test_get_user_bookings(self, client: TestClient):
        """Test getting all bookings for a user"""
        user_id = "test_user_id"
        response = client.get(f"/users/{user_id}/bookings")
        assert response.status_code in [200, 404]
