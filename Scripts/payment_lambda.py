import json
import os
from datetime import datetime, timezone

import boto3


sns_client = boto3.client("sns")
dynamodb = boto3.resource("dynamodb")
ORDER_RESULTS_TOPIC_ARN = os.environ["ORDER_RESULTS_TOPIC_ARN"]
inventory_table = dynamodb.Table(os.environ["INVENTORY_TABLE"])

# Best-effort idempotency for duplicate deliveries within a warm Lambda runtime.
PROCESSED_ORDER_IDS = set()


def log(level, message, **fields):
    entry = {
        "level": level,
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **fields,
    }
    print(json.dumps(entry))


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


def is_duplicate(order_id):
    if order_id in PROCESSED_ORDER_IDS:
        return True
    PROCESSED_ORDER_IDS.add(order_id)
    return False


def get_inventory_item(product_id):
    response = inventory_table.get_item(Key={"product_id": product_id}, ConsistentRead=True)
    return response.get("Item")


def validate_order_event(event):
    payload = event.get("payload", {})
    if not event.get("order_id"):
        raise ValueError("Missing order_id")
    if not payload.get("product_id"):
        raise ValueError("Missing product_id in payload")
    if payload.get("quantity", 0) <= 0:
        raise ValueError("Quantity must be greater than zero")
    if payload.get("amount") is None:
        raise ValueError("Missing amount in payload")


def process_record(record):
    event = json.loads(record["body"])
    order_id = event.get("order_id")

    log(
        "INFO",
        "Received payment request",
        order_id=order_id,
        event_type=event.get("event_type"),
    )

    if event.get("event_type") != "OrderCreated":
        log("INFO", "Skipping unsupported event type", order_id=order_id, event_type=event.get("event_type"))
        return

    validate_order_event(event)

    payload = event.get("payload", {})
    amount = payload["amount"]
    product_id = payload["product_id"]
    quantity = payload["quantity"]

    log("INFO", "Validated payment request", order_id=order_id, product_id=product_id, quantity=quantity)

    if is_duplicate(order_id):
        log("INFO", "Skipping duplicate payment event", order_id=order_id)
        return

    inventory_item = get_inventory_item(product_id)
    if not inventory_item:
        success = False
        reason = "Item is out of stock. Your order could not be placed."
    else:
        available_stock = int(inventory_item.get("stock", 0))
        if available_stock < quantity:
            success = False
            reason = "Item is out of stock. Your order could not be placed."
        elif amount >= 1000:
            success = False
            reason = "Payment declined: amount exceeds limit"
        else:
            success = True
            reason = None

    result_event = build_result_event(event, success=success, reason=reason)

    sns_client.publish(
        TopicArn=ORDER_RESULTS_TOPIC_ARN,
        Subject=result_event["event_type"],
        Message=json.dumps(result_event),
    )

    log(
        "INFO",
        "Published payment result",
        order_id=order_id,
        result_event_type=result_event["event_type"],
        reason=reason,
    )


def lambda_handler(event, context):
    batch_failures = []

    for record in event.get("Records", []):
        try:
            process_record(record)
        except Exception as exc:
            message_id = record.get("messageId", "unknown")
            log("ERROR", "Failed to process payment record", message_id=message_id, error=str(exc))
            batch_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_failures}
