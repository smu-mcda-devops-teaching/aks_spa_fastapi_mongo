import pytest
from fastapi.testclient import TestClient


class TestSearch:
    """Test suite for search routes"""

    def test_search_flights_no_filters(self, client: TestClient):
        """Test searching flights without filters"""
        response = client.get("/search/flights")
        assert response.status_code == 200

    def test_search_flights_with_filters(self, client: TestClient):
        """Test searching flights with filters"""
        response = client.get(
            "/search/flights?origin=JFK&destination=LAX&min_price=100&max_price=500"
        )
        assert response.status_code == 200

    def test_search_flights_by_date(self, client: TestClient):
        """Test searching flights by departure date"""
        response = client.get(
            "/search/flights?departure_date=2025-11-05"
        )
        assert response.status_code == 200

    def test_search_flights_by_route(self, client: TestClient):
        """Test searching flights by route"""
        response = client.get("/search/flights/by-route?origin=JFK&destination=LAX")
        assert response.status_code == 200

    def test_get_available_destinations(self, client: TestClient):
        """Test getting available destinations from origin"""
        response = client.get("/search/available-destinations?origin=JFK")
        assert response.status_code == 200

    def test_get_popular_routes(self, client: TestClient):
        """Test getting popular routes"""
        response = client.get("/search/popular-routes?limit=5")
        assert response.status_code == 200

    def test_get_popular_routes_default_limit(self, client: TestClient):
        """Test getting popular routes with default limit"""
        response = client.get("/search/popular-routes")
        assert response.status_code == 200
