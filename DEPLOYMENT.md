# Lambda Deployment Notes

This repository contains three Python 3.11 Lambda handlers:

- `Scripts/place_order.py`
- `Scripts/process_order.py`
- `Scripts/analytics.py`

## Dependencies

AWS Lambda Python runtimes often include `boto3`, but production deployments are more predictable when dependencies are pinned and packaged with the function or supplied through a Lambda layer.

This repo includes a `requirements.txt` with:

- `boto3`
- `botocore`

## Required environment variables

Set these on the Lambda functions that need them:

- `SNS_TOPIC_ARN`: required by `place_order.py`
- `DYNAMODB_TABLE_NAME`: required by `process_order.py`

`analytics.py` does not require either environment variable.

## Recommended handlers

Use these Lambda handler values:

- `place_order.lambda_handler` if the file is packaged as `place_order.py`
- `process_order.lambda_handler` if the file is packaged as `process_order.py`
- `analytics.lambda_handler` if the file is packaged as `analytics.py`

If you keep the files inside a `Scripts/` package in your deployment artifact, use:

- `Scripts.place_order.lambda_handler`
- `Scripts.process_order.lambda_handler`
- `Scripts.analytics.lambda_handler`

## Packaging locally

The quickest way to build deployment artifacts is with the repository `Makefile`:

```bash
make package
```

You can also package individual functions:

```bash
make package-place-order
make package-process-order
make package-analytics
```

This produces:

- `place_order.zip`
- `process_order.zip`
- `analytics.zip`

If you need to remove generated artifacts:

```bash
make clean
```

The `Makefile` uses the same packaging approach shown below.

Create one deployment artifact per Lambda so each function ships only what it needs.

Example for `place_order`:

```bash
mkdir -p build/place_order
pip install -r requirements.txt -t build/place_order
cp Scripts/place_order.py build/place_order/place_order.py
cd build/place_order && zip -r ../../place_order.zip .
```

Example for `process_order`:

```bash
mkdir -p build/process_order
pip install -r requirements.txt -t build/process_order
cp Scripts/process_order.py build/process_order/process_order.py
cd build/process_order && zip -r ../../process_order.zip .
```

Example for `analytics`:

```bash
mkdir -p build/analytics
pip install -r requirements.txt -t build/analytics
cp Scripts/analytics.py build/analytics/analytics.py
cd build/analytics && zip -r ../../analytics.zip .
```

## Terraform wiring checklist

- Set Lambda runtime to `python3.11`
- Point each Lambda `handler` to the correct module path
- Pass `SNS_TOPIC_ARN` into the place-order Lambda
- Pass `DYNAMODB_TABLE_NAME` into the process-order Lambda
- Enable `function_response_types = ["ReportBatchItemFailures"]` on the SQS event source mapping for `process_order`
- Attach IAM permissions:
  - `sns:Publish` for place-order
  - `dynamodb:PutItem` for process-order
  - `sqs:ReceiveMessage`, `sqs:DeleteMessage`, and `sqs:GetQueueAttributes` for SQS-triggered Lambdas

## Notes on `boto3`

If you rely on the runtime-provided SDK, the functions should work without packaging `boto3`. If you want deterministic builds and fewer runtime surprises, package the versions from `requirements.txt` or move them into a shared Lambda layer.
