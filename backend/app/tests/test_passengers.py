import pytest
from fastapi.testclient import TestClient


class TestPassengers:
    """Test suite for passengers routes"""

    def test_get_passengers(self, client: TestClient):
        """Test getting all passengers"""
        response = client.get("/passengers/")
        assert response.status_code == 200

    def test_get_passenger(self, client: TestClient):
        """Test getting a specific passenger"""
        passenger_id = "test_passenger_id"
        response = client.get(f"/passengers/{passenger_id}")
        assert response.status_code in [200, 404]

    def test_create_passenger(self, client: TestClient):
        """Test creating a new passenger"""
        passenger_data = {
            "user_id": "test_user_id",
            "first_name": "John",
            "last_name": "Smith",
            "date_of_birth": "1990-01-01T00:00:00Z",
            "passport_number": "P123456789",
            "nationality": "US"
        }
        response = client.post("/passengers/", json=passenger_data)
        assert response.status_code == 201

    def test_update_passenger(self, client: TestClient):
        """Test updating passenger information"""
        passenger_id = "test_passenger_id"
        update_data = {
            "passport_number": "P987654321"
        }
        response = client.put(f"/passengers/{passenger_id}", json=update_data)
        assert response.status_code in [200, 404]

    def test_delete_passenger(self, client: TestClient):
        """Test deleting a passenger"""
        passenger_id = "test_passenger_id"
        response = client.delete(f"/passengers/{passenger_id}")
        assert response.status_code in [204, 404]

    def test_get_user_passengers(self, client: TestClient):
        """Test getting all passengers for a user"""
        user_id = "test_user_id"
        response = client.get(f"/passengers/user/{user_id}")
        assert response.status_code in [200, 404]
