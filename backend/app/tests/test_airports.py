import pytest
from fastapi.testclient import TestClient


class TestAirports:
    """Test suite for airports routes"""

    def test_get_airports(self, client: TestClient):
        """Test getting all airports"""
        response = client.get("/airports/")
        assert response.status_code == 200

    def test_get_airport(self, client: TestClient):
        """Test getting a specific airport"""
        airport_id = "test_airport_id"
        response = client.get(f"/airports/{airport_id}")
        assert response.status_code in [200, 404]

    def test_get_airport_by_code(self, client: TestClient):
        """Test getting airport by IATA code"""
        code = "JFK"
        response = client.get(f"/airports/code/{code}")
        assert response.status_code in [200, 404]

    def test_create_airport(self, client: TestClient):
        """Test creating a new airport"""
        airport_data = {
            "code": "JFK",
            "name": "John F. Kennedy International Airport",
            "city": "New York",
            "country": "United States",
            "timezone": "America/New_York"
        }
        response = client.post("/airports/", json=airport_data)
        assert response.status_code == 201

    def test_update_airport(self, client: TestClient):
        """Test updating airport information"""
        airport_id = "test_airport_id"
        update_data = {
            "name": "Updated Airport Name",
            "code": "JFK",
            "city": "New York",
            "country": "United States",
            "timezone": "America/New_York"
        }
        response = client.put(f"/airports/{airport_id}", json=update_data)
        assert response.status_code in [200, 404]

    def test_delete_airport(self, client: TestClient):
        """Test deleting an airport"""
        airport_id = "test_airport_id"
        response = client.delete(f"/airports/{airport_id}")
        assert response.status_code in [204, 404]

    def test_search_airports(self, client: TestClient):
        """Test searching airports"""
        response = client.get("/airports/search/new york")
        assert response.status_code == 200
