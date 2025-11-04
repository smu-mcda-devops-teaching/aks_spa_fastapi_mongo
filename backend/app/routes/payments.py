from fastapi import APIRouter, HTTPException, status
from app.models import Payment, PaymentStatus, StripePayment, PayPalPayment
import stripe
import paypalrestsdk
import os
from typing import List

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
paypalrestsdk.configure({
    "mode": "sandbox",
    "client_id": os.getenv("PAYPAL_CLIENT_ID"),
    "client_secret": os.getenv("PAYPAL_CLIENT_SECRET")
})

router = APIRouter(prefix="/payments", tags=["payments"])

@router.get("/", response_model=List[Payment])
async def get_payments():
    """Get all payments (admin only)"""
    pass


@router.get("/{payment_id}", response_model=Payment)
async def get_payment(payment_id: str):
    """Get payment by ID"""
    pass


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=Payment)
async def process_payment(payment: Payment):
    """Process a new payment"""
    # TODO: Integrate with payment gateway
    pass


@router.put("/{payment_id}/status", response_model=Payment)
async def update_payment_status(payment_id: str, status: PaymentStatus):
    """Update payment status"""
    pass


@router.post("/{payment_id}/refund", response_model=Payment)
async def refund_payment(payment_id: str):
    """Process a refund for a payment"""
    pass


@router.get("/booking/{booking_id}", response_model=Payment)
async def get_payment_by_booking(booking_id: str):
    """Get payment for a specific booking"""
    pass

@router.post("/stripe")
async def stripe_payment(data: StripePayment):
    intent = stripe.PaymentIntent.create(
        amount=data.amount,
        currency="usd",
        payment_method=data.payment_method_id,
        confirm=True
    )
    return {"status": intent.status}

@router.post("/paypal")
async def paypal_payment(data: PayPalPayment):
    payment = paypalrestsdk.Payment.find(data.order_id)
    if payment.state == "approved":
        return {"status": "success"}
    return {"status": "failed"}
