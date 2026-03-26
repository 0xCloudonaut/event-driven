import json
import os
from datetime import datetime, timezone

import boto3


ses_client = boto3.client("ses")
SENDER_EMAIL = os.environ["SENDER_EMAIL"]

# Best-effort idempotency for duplicate deliveries within a warm Lambda runtime.
PROCESSED_NOTIFICATION_KEYS = set()


def log(level, message, **fields):
    entry = {
        "level": level,
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **fields,
    }
    print(json.dumps(entry))


def is_duplicate(notification_key):
    if notification_key in PROCESSED_NOTIFICATION_KEYS:
        return True
    PROCESSED_NOTIFICATION_KEYS.add(notification_key)
    return False


def build_email_content(event_type, order_id, reason=None):
    if event_type == "OrderConfirmed":
        return (
            f"Order {order_id} confirmed",
            f"Your order {order_id} was successfully processed.",
        )

    failure_reason = reason or "Your order could not be processed. Please try again later."
    return (
        f"Order {order_id} failed",
        f"Your order {order_id} could not be processed. Reason: {failure_reason}",
    )


def validate_notification_event(event):
    payload = event.get("payload", {})
    if not event.get("order_id"):
        raise ValueError("Missing order_id")
    if event.get("event_type") not in {"OrderConfirmed", "OrderFailed"}:
        raise ValueError("Unsupported event_type for notification")
    if not payload.get("email"):
        raise ValueError("Missing recipient email in payload")


def process_record(record):
    event = json.loads(record["body"])
    order_id = event.get("order_id")
    event_type = event.get("event_type")

    log("INFO", "Received notification event", order_id=order_id, event_type=event_type)

    if event_type not in {"OrderConfirmed", "OrderFailed"}:
        log("INFO", "Skipping unsupported notification event", order_id=order_id, event_type=event_type)
        return

    validate_notification_event(event)

    payload = event.get("payload", {})
    recipient_email = payload.get("email")
    reason = event.get("reason")
    notification_key = f"{order_id}:{event_type}"

    if is_duplicate(notification_key):
        log("INFO", "Skipping duplicate notification event", order_id=order_id, event_type=event_type)
        return

    subject, body_text = build_email_content(event_type, order_id, reason=reason)

    ses_client.send_email(
        Source=SENDER_EMAIL,
        Destination={"ToAddresses": [recipient_email]},
        Message={
            "Subject": {"Data": subject},
            "Body": {"Text": {"Data": body_text}},
        },
    )

    log("INFO", "Notification email sent", order_id=order_id, event_type=event_type, recipient_email=recipient_email)


def lambda_handler(event, context):
    batch_failures = []

    for record in event.get("Records", []):
        try:
            process_record(record)
        except Exception as exc:
            message_id = record.get("messageId", "unknown")
            log("ERROR", "Failed to process notification record", message_id=message_id, error=str(exc))
            batch_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_failures}
