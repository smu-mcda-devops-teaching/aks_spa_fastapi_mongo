import pytest
from fastapi.testclient import TestClient


class TestPayments:
    """Test suite for payments routes"""

    def test_get_payments(self, client: TestClient):
        """Test getting all payments"""
        response = client.get("/payments/")
        assert response.status_code in [200, 403]

    def test_get_payment(self, client: TestClient):
        """Test getting a specific payment"""
        payment_id = "test_payment_id"
        response = client.get(f"/payments/{payment_id}")
        assert response.status_code in [200, 404]

    def test_process_payment(self, client: TestClient):
        """Test processing a new payment"""
        payment_data = {
            "booking_id": "test_booking_id",
            "amount": 250.00,
            "payment_method": "credit_card",
            "status": "pending"
        }
        response = client.post("/payments/", json=payment_data)
        assert response.status_code == 201

    def test_update_payment_status(self, client: TestClient):
        """Test updating payment status"""
        payment_id = "test_payment_id"
        response = client.put(f"/payments/{payment_id}/status?status=completed")
        assert response.status_code in [200, 404]

    def test_refund_payment(self, client: TestClient):
        """Test processing a refund"""
        payment_id = "test_payment_id"
        response = client.post(f"/payments/{payment_id}/refund")
        assert response.status_code in [200, 404]

    def test_get_payment_by_booking(self, client: TestClient):
        """Test getting payment for a booking"""
        booking_id = "test_booking_id"
        response = client.get(f"/payments/booking/{booking_id}")
        assert response.status_code in [200, 404]
