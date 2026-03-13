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

# creating lambda function policy for order_analytics_event to poll and delete the order_analytics_queue
resource "aws_lambda_permission" "order_analytics_event" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_analytics_event.function_name
  principal     = "sns.amazonaws.com"

  # The ARN of the SNS topic
  source_arn = aws_sns_topic.order_processing_topic.arn
}

# creating a role for the order_analytics_event
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

# attaching the policy for order_analytics_event to the order_analytics_event role
resource "aws_iam_role_policy_attachment" "order_analytics_event" {
  policy_arn = aws_iam_policy.order_analytics_event.arn
  role       = aws_iam_role.order_analytics_event.name
}

# attaching the order_analytics_event role to the order_analytics_event lambda
resource "aws_lambda_function_role" "order_analytics_event" {
  function_name = aws_lambda_function.order_analytics_event.function_name
  role         = aws_iam_role.order_analytics_event.arn
}

# creating lambda function policy for order_processing_event to poll and delete the order_processing_queue
resource "aws_lambda_permission" "order_processing_event" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.order_processing_event.function_name
  principal     = "sns.amazonaws.com"

  # The ARN of the SNS topic
  source_arn = aws_sns_topic.order_processing_topic.arn
}

# creating a role for the order_processing_event
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

# attaching the policy for order_processing_event to the order_processing_event role
resource "aws_iam_role_policy_attachment" "order_processing_event" {
  policy_arn = aws_iam_policy.order_processing_event.arn
  role       = aws_iam_role.order_processing_event.name
}

# attaching the order_processing_event role to the order_processing_event lambda
resource "aws_lambda_function_role" "order_processing_event" {
  function_name = aws_lambda_function.order_processing_event.function_name
  role         = aws_iam_role.order_processing_event.arn
}
