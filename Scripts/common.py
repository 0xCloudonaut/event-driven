import json
from datetime import datetime, timezone


def log(level, message, **fields):
    entry = {
        "level": level,
        "message": message,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **fields,
    }
    print(json.dumps(entry))


def parse_sqs_record_body(record):
    return json.loads(record["body"])
