import json
import logging
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Any


logger = logging.getLogger()
logger.setLevel(logging.INFO)


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

    # SQS receives the SNS envelope when subscribed to an SNS topic.
    if isinstance(payload, dict) and "Message" in payload:
        payload = json.loads(payload["Message"])

    if not isinstance(payload, dict):
        raise ValueError("Message payload must be a JSON object.")

    return payload


def extract_order_value(order: dict[str, Any]) -> Decimal:
    try:
        value = Decimal(str(order["price"]))
    except (InvalidOperation, KeyError, TypeError) as exc:
        raise ValueError("Order price must be present and numeric.") from exc

    if value < 0:
        raise ValueError("Order price must not be negative.")

    return value


def emit_metrics(total_orders: int, total_order_value: Decimal) -> None:
    # Emit an Embedded Metric Format document so CloudWatch can extract metrics.
    # The flat key names also make the log line easy to scrape in external systems.
    logger.info(
        json.dumps(
            {
                "_aws": {
                    "Timestamp": int(datetime.now(timezone.utc).timestamp() * 1000),
                    "CloudWatchMetrics": [
                        {
                            "Namespace": "EventDriven/Orders",
                            "Dimensions": [["service"]],
                            "Metrics": [
                                {"Name": "total_orders_processed", "Unit": "Count"},
                                {"Name": "total_order_value", "Unit": "None"},
                            ],
                        }
                    ],
                },
                "service": "analytics-lambda",
                "total_orders_processed": total_orders,
                "total_order_value": float(total_order_value),
            }
        )
    )


def lambda_handler(event: dict[str, Any], context: Any) -> None:
    request_id = getattr(context, "aws_request_id", "unknown")
    total_orders = 0
    total_order_value = Decimal("0")

    for record in event.get("Records", []):
        message_id = record.get("messageId", "unknown")

        try:
            order = parse_sqs_record(record)
            order_value = extract_order_value(order)
            total_orders += 1
            total_order_value += order_value

            log_event(
                logging.INFO,
                "Analytics event processed.",
                request_id=request_id,
                sqs_message_id=message_id,
                order_id=order.get("order_id"),
                order_value=str(order_value),
            )
        except (ValueError, json.JSONDecodeError) as exc:
            log_event(
                logging.ERROR,
                "Analytics record skipped due to invalid payload.",
                request_id=request_id,
                sqs_message_id=message_id,
                error=str(exc),
            )
        except Exception as exc:  # pragma: no cover - defensive guard for Lambda runtime
            log_event(
                logging.ERROR,
                "Unhandled analytics processing error.",
                request_id=request_id,
                sqs_message_id=message_id,
                error=str(exc),
            )

    emit_metrics(total_orders=total_orders, total_order_value=total_order_value)
