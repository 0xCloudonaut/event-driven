locals {
  place_order_zip_path   = "${path.module}/${var.place_order_zip_path}"
  process_order_zip_path = "${path.module}/${var.process_order_zip_path}"
  analytics_zip_path     = "${path.module}/${var.analytics_zip_path}"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#################### Place Order Lambda ####################

resource "aws_iam_role" "order_place_event" {
  name               = "order-place-event-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "order_place_basic_execution" {
  role       = aws_iam_role.order_place_event.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "order_place_publish_policy" {
  name = "order-place-publish-policy"
  role = aws_iam_role.order_place_event.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.order_place_topic.arn
      }
    ]
  })
}

resource "aws_lambda_function" "order_place_event" {
  function_name = var.place_order_function_name
  runtime       = var.lambda_runtime
  role          = aws_iam_role.order_place_event.arn
  handler       = "place_order.lambda_handler"
  timeout       = 30
  filename      = local.place_order_zip_path

  source_code_hash = filebase64sha256(local.place_order_zip_path)

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.order_place_topic.arn
    }
  }
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvokePlaceOrder"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_place_event.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.order_place_api.execution_arn}/*/POST/order"
}

#################### Analytics Lambda ####################

resource "aws_iam_role" "order_analytics_event" {
  name               = "order-analytics-event-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "order_analytics_basic_execution" {
  role       = aws_iam_role.order_analytics_event.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "order_analytics_sqs_execution" {
  role       = aws_iam_role.order_analytics_event.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_function" "order_analytics_event" {
  function_name = var.analytics_function_name
  runtime       = var.lambda_runtime
  role          = aws_iam_role.order_analytics_event.arn
  handler       = "analytics.lambda_handler"
  timeout       = 60
  filename      = local.analytics_zip_path

  source_code_hash = filebase64sha256(local.analytics_zip_path)
}

resource "aws_lambda_event_source_mapping" "order_analytics_event" {
  event_source_arn = aws_sqs_queue.order_analytics_main.arn
  function_name    = aws_lambda_function.order_analytics_event.arn
  enabled          = true
  batch_size       = 10
}

#################### Process Order Lambda ####################

resource "aws_iam_role" "order_processing_event" {
  name               = "order-processing-event-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "order_processing_basic_execution" {
  role       = aws_iam_role.order_processing_event.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "order_processing_sqs_execution" {
  role       = aws_iam_role.order_processing_event.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy" "order_processing_dynamodb_policy" {
  name = "order-processing-dynamodb-policy"
  role = aws_iam_role.order_processing_event.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem"
        ]
        Resource = aws_dynamodb_table.orders.arn
      }
    ]
  })
}

resource "aws_lambda_function" "order_processing_event" {
  function_name = var.process_order_function_name
  runtime       = var.lambda_runtime
  role          = aws_iam_role.order_processing_event.arn
  handler       = "process_order.lambda_handler"
  timeout       = 60
  filename      = local.process_order_zip_path

  source_code_hash = filebase64sha256(local.process_order_zip_path)

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.orders.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "order_processing_event" {
  event_source_arn        = aws_sqs_queue.order_processing_main.arn
  function_name           = aws_lambda_function.order_processing_event.arn
  enabled                 = true
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}
