import json
import os
import uuid
from datetime import datetime, timezone
from decimal import Decimal
from urllib import request

import boto3


AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
API_GATEWAY_URL = os.environ["API_GATEWAY_URL"]
INVENTORY_TABLE = os.environ["INVENTORY_TABLE"]
CUSTOMER_EMAIL = os.getenv("CUSTOMER_EMAIL", "user@example.com")

dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
inventory_table = dynamodb.Table(INVENTORY_TABLE)


def log(level, message, **fields):
    entry = {
        "level": level,
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **fields,
    }
    print(json.dumps(entry))


def to_int(value):
    if isinstance(value, Decimal):
        return int(value)
    return int(value or 0)


def load_inventory_items():
    response = inventory_table.scan()
    items = response.get("Items", [])
    while "LastEvaluatedKey" in response:
        response = inventory_table.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
        items.extend(response.get("Items", []))
    return items


def build_order_event(product_id, quantity, amount, email):
    return {
        "request_id": str(uuid.uuid4()),
        "product_id": product_id,
        "quantity": quantity,
        "amount": amount,
        "email": email,
    }


def build_simulation_events(items, email):
    if not items:
        raise ValueError("Inventory table is empty. Seed at least one product before simulating traffic.")

    in_stock_items = [item for item in items if to_int(item.get("stock", 0)) > 0]
    if not in_stock_items:
        raise ValueError("No in-stock items found in DynamoDB. Seed stock before running the simulator.")

    success_item = in_stock_items[0]
    success_stock = to_int(success_item["stock"])

    events = [
        {
            "scenario": "successful_order",
            "payload": build_order_event(
                product_id=success_item["product_id"],
                quantity=1,
                amount=100,
                email=email,
            ),
        },
        {
            "scenario": "payment_declined",
            "payload": build_order_event(
                product_id=success_item["product_id"],
                quantity=1,
                amount=1500,
                email=email,
            ),
        },
        {
            "scenario": "out_of_stock",
            "payload": build_order_event(
                product_id=success_item["product_id"],
                quantity=success_stock + 1,
                amount=100,
                email=email,
            ),
        },
    ]

    return events


def post_order(api_gateway_url, payload):
    # The public API accepts a plain order request; the payment Lambda transforms it
    # into the internal event shape before publishing to SNS.
    http_request = request.Request(
        api_gateway_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with request.urlopen(http_request, timeout=10) as response:
        response_body = response.read().decode("utf-8")
        return {
            "status_code": response.status,
            "body": response_body,
        }


def main():
    items = load_inventory_items()
    events = build_simulation_events(items, CUSTOMER_EMAIL)

    log("INFO", "Loaded inventory for traffic simulation", inventory_table=INVENTORY_TABLE, item_count=len(items))

    for event in events:
        scenario = event["scenario"]
        payload = event["payload"]

        log(
            "INFO",
            "Sending order to API Gateway",
            scenario=scenario,
            request_id=payload["request_id"],
            product_id=payload["product_id"],
            quantity=payload["quantity"],
            amount=payload["amount"],
        )

        try:
            response = post_order(API_GATEWAY_URL, payload)
            log(
                "INFO",
                "API Gateway accepted order request",
                scenario=scenario,
                request_id=payload["request_id"],
                status_code=response["status_code"],
                response_body=response["body"],
            )
        except Exception as exc:
            log(
                "ERROR",
                "Failed to send order to API Gateway",
                scenario=scenario,
                request_id=payload["request_id"],
                error=str(exc),
            )


if __name__ == "__main__":
    main()
