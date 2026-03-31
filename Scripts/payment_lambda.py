import json
import os

import boto3
from botocore.exceptions import ClientError

from common import log
from order_events import (
    build_order_event,
    build_result_event,
    normalize_order_request,
    parse_api_gateway_body,
    response,
)

sns_client = boto3.client("sns")
dynamodb = boto3.resource("dynamodb")
ORDER_RESULTS_TOPIC_ARN = os.environ["ORDER_RESULTS_TOPIC_ARN"]
inventory_table = dynamodb.Table(os.environ["INVENTORY_TABLE"])


def get_inventory_item(product_id):
    response = inventory_table.get_item(Key={"product_id": product_id}, ConsistentRead=True)
    return response.get("Item")


def reserve_inventory(order_id, product_id, quantity):
    try:
        inventory_table.update_item(
            Key={"product_id": product_id},
            UpdateExpression="SET stock = stock - :quantity ADD processed_order_ids :order_id_set",
            ConditionExpression="stock >= :quantity AND (attribute_not_exists(processed_order_ids) OR NOT contains(processed_order_ids, :order_id))",
            ExpressionAttributeValues={
                ":quantity": quantity,
                ":order_id": order_id,
                ":order_id_set": {order_id},
            },
        )
        return True, None
    except ClientError as exc:
        if exc.response["Error"]["Code"] != "ConditionalCheckFailedException":
            raise

        current_item = get_inventory_item(product_id)
        if current_item and order_id in current_item.get("processed_order_ids", set()):
            return True, None

        return False, "Item is out of stock. Your order could not be placed."


def evaluate_payment(order_event):
    payload = order_event["payload"]
    amount = payload["amount"]
    product_id = payload["product_id"]
    quantity = payload["quantity"]

    if amount >= 1000:
        return False, "Payment declined: amount exceeds limit"

    return reserve_inventory(order_event["order_id"], product_id, quantity)


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
