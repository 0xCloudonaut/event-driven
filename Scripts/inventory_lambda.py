import json
import os
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError


dynamodb = boto3.resource("dynamodb")
inventory_table = dynamodb.Table(os.environ["INVENTORY_TABLE"])


def log(level, message, **fields):
    entry = {
        "level": level,
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **fields,
    }
    print(json.dumps(entry))


def get_inventory_item(product_id):
    response = inventory_table.get_item(Key={"product_id": product_id}, ConsistentRead=True)
    return response.get("Item")


def validate_inventory_event(event):
    payload = event.get("payload", {})
    if not event.get("order_id"):
        raise ValueError("Missing order_id")
    if not payload.get("product_id"):
        raise ValueError("Missing product_id in payload")
    if payload.get("quantity", 0) <= 0:
        raise ValueError("Quantity must be greater than zero")


def process_record(record):
    event = json.loads(record["body"])
    order_id = event.get("order_id")
    event_type = event.get("event_type")

    log("INFO", "Received inventory event", order_id=order_id, event_type=event_type)

    if event_type != "OrderConfirmed":
        log("INFO", "Skipping non-confirmed order event", order_id=order_id, event_type=event_type)
        return

    validate_inventory_event(event)

    payload = event.get("payload", {})
    product_id = payload.get("product_id")
    quantity = payload.get("quantity", 0)

    log("INFO", "Validated inventory event", order_id=order_id, product_id=product_id, quantity=quantity)

    if not product_id:
        raise ValueError("Missing product_id in payload")
    if quantity <= 0:
        raise ValueError("Quantity must be greater than zero")

    try:
        # Deduct stock only once per order by recording the processed order_id on the same item.
        inventory_table.update_item(
            Key={"product_id": product_id},
            UpdateExpression="SET stock = stock - :quantity ADD processed_order_ids :order_id_set",
            ConditionExpression="stock >= :quantity AND (attribute_not_exists(processed_order_ids) OR NOT contains(processed_order_ids, :order_id))",
            ExpressionAttributeValues={
                ":quantity": quantity,
                ":order_id": order_id,
                ":order_id_set": {order_id},
            },
            ReturnValues="UPDATED_NEW",
        )
        updated_item = get_inventory_item(product_id)
        remaining_stock = int(updated_item.get("stock", 0)) if updated_item else None
        log(
            "INFO",
            "Inventory updated",
            order_id=order_id,
            product_id=product_id,
            quantity=quantity,
            remaining_stock=remaining_stock,
        )
    except ClientError as exc:
        error_code = exc.response["Error"]["Code"]
        if error_code == "ConditionalCheckFailedException":
            current_item = get_inventory_item(product_id)
            processed_order_ids = current_item.get("processed_order_ids", set()) if current_item else set()
            if order_id in processed_order_ids:
                log("INFO", "Skipping duplicate inventory event", order_id=order_id, product_id=product_id)
                return

            current_stock = int(current_item.get("stock", 0)) if current_item else 0
            log(
                "ERROR",
                "Inventory check failed after payment confirmation",
                order_id=order_id,
                product_id=product_id,
                quantity=quantity,
                current_stock=current_stock,
            )
            return
        raise


def lambda_handler(event, context):
    batch_failures = []

    for record in event.get("Records", []):
        try:
            process_record(record)
        except Exception as exc:
            message_id = record.get("messageId", "unknown")
            log("ERROR", "Failed to process inventory record", message_id=message_id, error=str(exc))
            batch_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_failures}
