import json
import logging
import os
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError


logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client("sns")
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def log_event(level: int, message: str, **fields: Any) -> None:
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": logging.getLevelName(level),
        "message": message,
        **fields,
    }
    logger.log(level, json.dumps(payload, default=str))


def build_response(status_code: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def parse_body(event: dict[str, Any]) -> dict[str, Any]:
    body = event.get("body")
    if body is None:
        raise ValueError("Request body is required.")

    if event.get("isBase64Encoded"):
        raise ValueError("Base64-encoded payloads are not supported by this handler.")

    if isinstance(body, str):
        try:
            parsed = json.loads(body)
        except json.JSONDecodeError as exc:
            raise ValueError("Request body must be valid JSON.") from exc
    elif isinstance(body, dict):
        parsed = body
    else:
        raise ValueError("Request body must be a JSON object.")

    if not isinstance(parsed, dict):
        raise ValueError("Request body must be a JSON object.")

    return parsed


def validate_order(payload: dict[str, Any]) -> dict[str, Any]:
    required_fields = ("order_id", "item", "price")
    missing_fields = [field for field in required_fields if field not in payload]
    if missing_fields:
        raise ValueError(f"Missing required field(s): {', '.join(missing_fields)}")

    order_id = str(payload["order_id"]).strip()
    item = str(payload["item"]).strip()

    if not order_id:
        raise ValueError("order_id must be a non-empty string.")
    if not item:
        raise ValueError("item must be a non-empty string.")

    try:
        price = Decimal(str(payload["price"]))
    except (InvalidOperation, TypeError) as exc:
        raise ValueError("price must be a valid number.") from exc

    if price <= 0:
        raise ValueError("price must be greater than 0.")

    # Keep the event payload stable and explicit for downstream consumers.
    return {
        "order_id": order_id,
        "item": item,
        "price": str(price),
        "created_at": payload.get("created_at") or datetime.now(timezone.utc).isoformat(),
    }


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    request_id = getattr(context, "aws_request_id", "unknown")

    try:
        payload = parse_body(event)
        order = validate_order(payload)
        response = sns_client.publish(
            TopicArn=SNS_TOPIC_ARN,
            Message=json.dumps(order),
            MessageAttributes={
                "event_type": {
                    "DataType": "String",
                    "StringValue": "order.created",
                }
            },
        )

        log_event(
            logging.INFO,
            "Order published to SNS.",
            request_id=request_id,
            order_id=order["order_id"],
            topic_arn=SNS_TOPIC_ARN,
            sns_message_id=response["MessageId"],
        )
        return build_response(
            202,
            {
                "message": "Order accepted.",
                "order_id": order["order_id"],
                "message_id": response["MessageId"],
            },
        )
    except ValueError as exc:
        log_event(
            logging.WARNING,
            "Order validation failed.",
            request_id=request_id,
            error=str(exc),
        )
        return build_response(400, {"message": str(exc)})
    except (ClientError, BotoCoreError) as exc:
        log_event(
            logging.ERROR,
            "Failed to publish order to SNS.",
            request_id=request_id,
            error=str(exc),
        )
        return build_response(500, {"message": "Failed to publish order."})
    except Exception as exc:  # pragma: no cover - defensive guard for Lambda runtime
        log_event(
            logging.ERROR,
            "Unhandled error while placing order.",
            request_id=request_id,
            error=str(exc),
        )
        return build_response(500, {"message": "Internal server error."})
