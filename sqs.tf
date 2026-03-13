# creating an SQS queue
resource "aws_sqs_queue" "my_queue" {
  name = "my_queue"
}

# creating an SQS queue policy
resource "aws_sqs_queue_policy" "my_queue_policy" {
  queue_url = aws_sqs_queue.my_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.my_queue.arn
      }
    ]
  })
}

# creating an SQS event source mapping
resource "aws_lambda_event_source_mapping" "my_event_source" {
  event_source_arn = aws_sqs_queue.my_queue.arn
  function_name    = aws_lambda_function.my_lambda.arn
}

# dead letter queue
resource "aws_sqs_queue" "my_dead_letter_queue" {
  name = "my_dead_letter_queue"
}

# creating a dead letter queue policy
resource "aws_sqs_queue_policy" "my_dead_letter_queue_policy" {
  queue_url = aws_sqs_queue.my_dead_letter_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.my_dead_letter_queue.arn
      }
    ]
  })
}

# creating a dead letter queue event source mapping
resource "aws_lambda_event_source_mapping" "my_dead_letter_event_source" {
  event_source_arn = aws_sqs_queue.my_dead_letter_queue.arn
  function_name    = aws_lambda_function.my_lambda.arn
}