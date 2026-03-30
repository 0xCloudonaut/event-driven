import base64
import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation

import boto3


sns_client = boto3.client("sns")
dynamodb = boto3.resource("dynamodb")
ORDER_RESULTS_TOPIC_ARN = os.environ["ORDER_RESULTS_TOPIC_ARN"]
inventory_table = dynamodb.Table(os.environ["INVENTORY_TABLE"])

# Best-effort idempotency for duplicate deliveries within a warm Lambda runtime.
PROCESSED_REQUEST_IDS = set()


def log(level, message, **fields):
    entry = {
        "level": level,
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **fields,
    }
    print(json.dumps(entry))


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
    return {
        "event_id": order_request.get("request_id") or str(uuid.uuid4()),
        "event_type": "OrderCreated",
        "order_id": f"ord-{uuid.uuid4().hex[:12]}",
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


def is_duplicate(request_id):
    if request_id in PROCESSED_REQUEST_IDS:
        return True
    PROCESSED_REQUEST_IDS.add(request_id)
    return False


def get_inventory_item(product_id):
    response = inventory_table.get_item(Key={"product_id": product_id}, ConsistentRead=True)
    return response.get("Item")


def evaluate_payment(order_event):
    payload = order_event["payload"]
    amount = payload["amount"]
    product_id = payload["product_id"]
    quantity = payload["quantity"]

    inventory_item = get_inventory_item(product_id)
    if not inventory_item:
        return False, "Item is out of stock. Your order could not be placed."

    available_stock = int(inventory_item.get("stock", 0))
    if available_stock < quantity:
        return False, "Item is out of stock. Your order could not be placed."

    if amount >= 1000:
        return False, "Payment declined: amount exceeds limit"

    return True, None


def publish_result_event(result_event):
    sns_client.publish(
        TopicArn=ORDER_RESULTS_TOPIC_ARN,
        Subject=result_event["event_type"],
        Message=json.dumps(result_event),
    )


def lambda_handler(event, context):
    try:
        request_payload = parse_api_gateway_body(event)
        order_request = normalize_order_request(request_payload)
        order_event = build_order_event(order_request)

        log(
            "INFO",
            "Received payment request from API Gateway",
            order_id=order_event["order_id"],
            product_id=order_request["product_id"],
            quantity=order_request["quantity"],
            amount=order_request["amount"],
        )

        if is_duplicate(order_event["event_id"]):
            log("INFO", "Skipping duplicate payment request", event_id=order_event["event_id"])
            return response(
                200,
                {
                    "message": "Duplicate payment request ignored",
                    "order_id": order_event["order_id"],
                },
            )

        success, reason = evaluate_payment(order_event)
        result_event = build_result_event(order_event, success=success, reason=reason)
        publish_result_event(result_event)

        log(
            "INFO",
            "Published payment result",
            order_id=order_event["order_id"],
            result_event_type=result_event["event_type"],
            reason=reason,
        )

        return response(
            200,
            {
                "message": "Order processed",
                "order_id": result_event["order_id"],
                "event_type": result_event["event_type"],
                "reason": reason,
            },
        )
    except ValueError as exc:
        log("ERROR", "Invalid API Gateway order request", error=str(exc))
        return response(400, {"message": str(exc)})
    except Exception as exc:
        log("ERROR", "Unexpected payment processing failure", error=str(exc))
        return response(500, {"message": "Internal server error"})


def handler(event, context):
    return lambda_handler(event, context)
