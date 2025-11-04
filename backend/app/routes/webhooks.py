from fastapi import APIRouter, Request, HTTPException
import stripe
import os

router = APIRouter(prefix="/webhooks", tags=["Webhooks"])
stripe.api_key = os.getenv("STRIPE_SECRET_KEY")
endpoint_secret = os.getenv("STRIPE_WEBHOOK_SECRET")

@router.post("/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("Stripe-Signature")
    try:
        event = stripe.Webhook.construct_event(payload, sig_header, endpoint_secret)
    except stripe.SignatureVerificationError:
        raise HTTPException(status_code=400, detail="Invalid signature")

    if event["type"] == "payment_intent.succeeded":
        intent = event["data"]["object"]
        print(f"Payment succeeded for {intent['id']}")
    return {"status": "received"}

@router.post("/paypal")
async def paypal_webhook(request: Request):
    body = await request.json()
    event_type = body.get("event_type")
    if event_type == "PAYMENT.CAPTURE.COMPLETED":
        resource = body.get("resource", {})
        order_id = resource.get("id")
        print(f"PayPal payment completed for {order_id}")
    return {"status": "received"}
