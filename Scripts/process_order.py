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

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])


def log_event(level: int, message: str, **fields: Any) -> None:
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": logging.getLevelName(level),
        "message": message,
        **fields,
    }
    logger.log(level, json.dumps(payload, default=str))


def parse_sqs_record(record: dict[str, Any]) -> dict[str, Any]:
    body = record.get("body", "")
    payload = json.loads(body)

    # When SQS is subscribed to SNS, the original message is nested in the SNS envelope.
    if isinstance(payload, dict) and "Message" in payload:
        payload = json.loads(payload["Message"])

    if not isinstance(payload, dict):
        raise ValueError("Message payload must be a JSON object.")

    return payload


def validate_order(order: dict[str, Any]) -> dict[str, Any]:
    required_fields = ("order_id", "item", "price")
    missing_fields = [field for field in required_fields if field not in order]
    if missing_fields:
        raise ValueError(f"Missing required field(s): {', '.join(missing_fields)}")

    order_id = str(order["order_id"]).strip()
    item = str(order["item"]).strip()

    if not order_id:
        raise ValueError("order_id must be a non-empty string.")
    if not item:
        raise ValueError("item must be a non-empty string.")

    try:
        price = Decimal(str(order["price"]))
    except (InvalidOperation, TypeError) as exc:
        raise ValueError("price must be a valid number.") from exc

    if price <= 0:
        raise ValueError("price must be greater than 0.")

    created_at = str(order.get("created_at") or datetime.now(timezone.utc).isoformat())

    return {
        "order_id": order_id,
        "item": item,
        "price": price,
        "created_at": created_at,
    }


def put_order(order: dict[str, Any]) -> None:
    # Conditional put gives us lightweight idempotency for duplicate deliveries
    # of the same logical event (same order_id + created_at).
    table.put_item(
        Item=order,
        ConditionExpression="attribute_not_exists(order_id) AND attribute_not_exists(created_at)",
    )


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    batch_failures: list[dict[str, str]] = []
    request_id = getattr(context, "aws_request_id", "unknown")

    for record in event.get("Records", []):
        message_id = record.get("messageId", "unknown")

        try:
            order = validate_order(parse_sqs_record(record))
            put_order(order)
            log_event(
                logging.INFO,
                "Order persisted to DynamoDB.",
                request_id=request_id,
                sqs_message_id=message_id,
                order_id=order["order_id"],
                table_name=table.name,
            )
        except ClientError as exc:
            error_code = exc.response.get("Error", {}).get("Code")
            if error_code == "ConditionalCheckFailedException":
                log_event(
                    logging.INFO,
                    "Duplicate order event skipped.",
                    request_id=request_id,
                    sqs_message_id=message_id,
                    error_code=error_code,
                )
                continue

            batch_failures.append({"itemIdentifier": message_id})
            log_event(
                logging.ERROR,
                "DynamoDB write failed for SQS record.",
                request_id=request_id,
                sqs_message_id=message_id,
                error=str(exc),
            )
        except (ValueError, json.JSONDecodeError, BotoCoreError) as exc:
            batch_failures.append({"itemIdentifier": message_id})
            log_event(
                logging.ERROR,
                "Failed to process SQS record.",
                request_id=request_id,
                sqs_message_id=message_id,
                error=str(exc),
            )
        except Exception as exc:  # pragma: no cover - defensive guard for Lambda runtime
            batch_failures.append({"itemIdentifier": message_id})
            log_event(
                logging.ERROR,
                "Unhandled error while processing SQS record.",
                request_id=request_id,
                sqs_message_id=message_id,
                error=str(exc),
            )

    return {"batchItemFailures": batch_failures}
