import pytest
from fastapi.testclient import TestClient


class TestFlights:
    """Test suite for flights routes"""

    def test_get_flights(self, client: TestClient):
        """Test getting all flights"""
        response = client.get("/flights/")
        assert response.status_code == 200

    def test_get_flight(self, client: TestClient):
        """Test getting a specific flight by ID"""
        flight_id = "test_flight_id"
        response = client.get(f"/flights/{flight_id}")
        assert response.status_code in [200, 404]

    def test_create_flight(self, client: TestClient):
        """Test creating a new flight"""
        flight_data = {
            "flight_number": "AA123",
            "origin": "JFK",
            "destination": "LAX",
            "departure_time": "2025-11-05T10:00:00Z",
            "arrival_time": "2025-11-05T13:00:00Z"
        }
        response = client.post("/flights/", json=flight_data)
        assert response.status_code in [200, 201]

    def test_update_flight(self, client: TestClient):
        """Test updating a flight"""
        flight_id = "test_flight_id"
        update_data = {
            "departure_time": "2025-11-05T11:00:00Z"
        }
        response = client.put(f"/flights/{flight_id}", json=update_data)
        assert response.status_code in [200, 404]

    def test_delete_flight(self, client: TestClient):
        """Test deleting a flight"""
        flight_id = "test_flight_id"
        response = client.delete(f"/flights/{flight_id}")
        assert response.status_code in [200, 204, 404]
