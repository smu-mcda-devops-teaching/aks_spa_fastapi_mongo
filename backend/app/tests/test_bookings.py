import pytest
from fastapi.testclient import TestClient


class TestBookings:
    """Test suite for bookings routes"""

    def test_get_bookings(self, client: TestClient):
        """Test getting all bookings"""
        response = client.get("/bookings/")
        assert response.status_code == 200

    def test_get_booking(self, client: TestClient):
        """Test getting a specific booking by ID"""
        booking_id = "test_booking_id"
        response = client.get(f"/bookings/{booking_id}")
        assert response.status_code in [200, 404]

    def test_create_booking(self, client: TestClient):
        """Test creating a new booking"""
        booking_data = {
            "flight_id": "test_flight_id",
            "passenger_name": "John Doe",
            "passenger_email": "john.doe@example.com",
            "seat_number": "12A"
        }
        response = client.post("/bookings/", json=booking_data)
        assert response.status_code in [200, 201]

    def test_update_booking(self, client: TestClient):
        """Test updating a booking"""
        booking_id = "test_booking_id"
        update_data = {
            "seat_number": "15B"
        }
        response = client.put(f"/bookings/{booking_id}", json=update_data)
        assert response.status_code in [200, 404]

    def test_delete_booking(self, client: TestClient):
        """Test deleting a booking"""
        booking_id = "test_booking_id"
        response = client.delete(f"/bookings/{booking_id}")
        assert response.status_code in [200, 204, 404]
