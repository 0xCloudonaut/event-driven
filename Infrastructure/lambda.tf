# creating lambda function for creating event of order place
resource "aws_lambda_function" "order_place_event" {
  function_name = "order_place_event"
  runtime      = "python3.8"
  role        = aws_iam_role.lambda_exec.arn
  handler     = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      foo = "bar"
    }
  }
}

# creating a role for the order placing event
resource "aws_iam_role" "order_place_event" {
  name = "order_place_event_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

# attaching the policy to the order placing event to push the message to the SNS
resource "aws_iam_role_policy_attachment" "order_place_event" {
  policy_arn = aws_iam_policy.AWSLambdaSNSPublishPolicy.arn
  role       = aws_iam_role.order_place_event.name
}

# creating lambda function for creating event of order analytics
resource "aws_lambda_function" "order_analytics_event" {
  function_name = "order_analytics_event"
  runtime      = "python3.8"
  role        = aws_iam_role.lambda_exec.arn
  handler     = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      foo = "bar"
    }
  }
}

# create event source mapping for order_analytics_event
resource "aws_lambda_event_source_mapping" "order_analytics_event" {
  event_source_arn = aws_sqs_queue.order_analytics_queue.arn
  function_name    = aws_lambda_function.order_analytics_event.function_name
  enabled         = true
}

# create AWSLambdaSQSQueueExecutionRole for order_analytics_event to poll and delete from order_analytics_queue
resource "aws_iam_role" "order_analytics_event" {
  name = "order_analytics_event_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

#attach policy AWSLambdaSQSQueueExecutionRole to the order_analytics_event role
resource "aws_iam_role_policy_attachment" "order_analytics_event" {
  policy_arn = aws_iam_policy.AWSLambdaSQSQueueExecutionRole.arn
  role       = aws_iam_role.order_analytics_event.name
}

# create lambda function for processing order events
resource "aws_lambda_function" "order_processing_event" {
  function_name = "order_processing_event"
  runtime      = "python3.8"
  role        = aws_iam_role.lambda_exec.arn
  handler     = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      foo = "bar"
    }
  }
}

# create event source mapping for order_processing_event
resource "aws_lambda_event_source_mapping" "order_processing_event" {
  event_source_arn = aws_sqs_queue.order_processing_queue.arn
  function_name    = aws_lambda_function.order_processing_event.function_name
  enabled         = true
}

# create AWSLambdaSQSQueueExecutionRole for order_processing_event to poll and delete from order_processing_queue
resource "aws_iam_role" "order_processing_event" {
  name = "order_processing_event_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      }
    ]
  })
}

#attach policy AWSLambdaSQSQueueExecutionRole to the order_processing_event role
resource "aws_iam_role_policy_attachment" "order_processing_event" {
  policy_arn = aws_iam_policy.AWSLambdaSQSQueueExecutionRole.arn
  role       = aws_iam_role.order_processing_event.name
}