import pytest
from fastapi.testclient import TestClient


class TestAirlines:
    """Test suite for airlines routes"""

    def test_get_airlines(self, client: TestClient):
        """Test getting all airlines"""
        response = client.get("/airlines/")
        assert response.status_code == 200

    def test_get_airline(self, client: TestClient):
        """Test getting a specific airline"""
        airline_id = "test_airline_id"
        response = client.get(f"/airlines/{airline_id}")
        assert response.status_code in [200, 404]

    def test_create_airline(self, client: TestClient):
        """Test creating a new airline"""
        airline_data = {
            "name": "Test Airlines",
            "code": "TA",
            "logo_url": "https://example.com/logo.png",
            "country": "US"
        }
        response = client.post("/airlines/", json=airline_data)
        assert response.status_code == 201

    def test_update_airline(self, client: TestClient):
        """Test updating airline information"""
        airline_id = "test_airline_id"
        update_data = {
            "name": "Updated Airlines",
            "code": "UA",
            "country": "US"
        }
        response = client.put(f"/airlines/{airline_id}", json=update_data)
        assert response.status_code in [200, 404]

    def test_delete_airline(self, client: TestClient):
        """Test deleting an airline"""
        airline_id = "test_airline_id"
        response = client.delete(f"/airlines/{airline_id}")
        assert response.status_code in [204, 404]

    def test_get_airline_flights(self, client: TestClient):
        """Test getting all flights for an airline"""
        airline_id = "test_airline_id"
        response = client.get(f"/airlines/{airline_id}/flights")
        assert response.status_code in [200, 404]
