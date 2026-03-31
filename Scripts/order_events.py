import base64
import json
import uuid
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def parse_api_gateway_body(event):
    if not isinstance(event, dict):
        raise ValueError("Event must be a JSON object")

    if "body" not in event:
        return event

    raw_body = event["body"]
    if raw_body is None:
        raise ValueError("Request body is required")

    if event.get("isBase64Encoded"):
        raw_body = base64.b64decode(raw_body).decode("utf-8")

    if isinstance(raw_body, str):
        if not raw_body.strip():
            raise ValueError("Request body is required")
        return json.loads(raw_body)

    if isinstance(raw_body, dict):
        return raw_body

    raise ValueError("Unsupported request body format")


def normalize_order_request(payload):
    if not isinstance(payload, dict):
        raise ValueError("Request body must be a JSON object")

    product_id = str(payload.get("product_id", "")).strip()
    email = str(payload.get("email", "")).strip()

    if not product_id:
        raise ValueError("product_id is required")
    if "@" not in email:
        raise ValueError("email must be a valid address")

    try:
        quantity = int(payload.get("quantity"))
    except (TypeError, ValueError):
        raise ValueError("quantity must be an integer greater than zero") from None

    if quantity <= 0:
        raise ValueError("quantity must be an integer greater than zero")

    if payload.get("amount") is None:
        raise ValueError("amount is required")

    try:
        amount = Decimal(str(payload.get("amount")))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError("amount must be a valid number") from None

    if amount <= 0:
        raise ValueError("amount must be greater than zero")

    request_id = payload.get("request_id")
    if request_id is not None:
        request_id = str(request_id).strip()
        if not request_id:
            raise ValueError("request_id cannot be empty when provided")

    return {
        "request_id": request_id,
        "product_id": product_id,
        "quantity": quantity,
        "amount": float(amount),
        "email": email,
    }


def build_order_event(order_request):
    request_id = order_request.get("request_id")
    order_suffix = request_id or uuid.uuid4().hex[:12]

    return {
        "event_id": request_id or str(uuid.uuid4()),
        "event_type": "OrderCreated",
        "order_id": f"ord-{order_suffix}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "payload": order_request,
    }


def build_result_event(event, success, reason=None):
    result_event = {
        "event_id": event["event_id"],
        "event_type": "OrderConfirmed" if success else "OrderFailed",
        "order_id": event["order_id"],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "payload": event.get("payload", {}),
    }
    if reason:
        result_event["reason"] = reason
    return result_event
