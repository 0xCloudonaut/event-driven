////////////////////////////// Order processing Queue setup //////////////////////////////

# creating a dead letter queue for order processing
resource "aws_sqs_queue" "order_processing_dlq" {
  name = "order_processing_dlq"
}

# creating main order processing queue named order processing main with dead letter queue and policy
resource "aws_sqs_queue" "order_processing_main" {
  name = "order_processing_main"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_processing_dlq.arn
    maxReceiveCount     = 5
  })
}

# allow access for SNS order processing topic
resource "aws_sqs_queue_policy" "order_processing_main_policy" {
  queue_url = aws_sqs_queue.order_processing_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.order_processing_main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_processing.arn
          }
        }
      }
    ]
  })
}

////////////////////////////// Order processing Queue setup //////////////////////////////

# creating dead letter queue for order analytics
resource "aws_sqs_queue" "order_analytics_dlq" {
  name = "order_analytics_dlq"
}

# creating main order analytics queue named order analytics main with dead letter queue and policy
resource "aws_sqs_queue" "order_analytics_main" {
  name = "order_analytics_main"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_analytics_dlq.arn
    maxReceiveCount     = 5
  })
}

# allow access for SNS order analytics topic
resource "aws_sqs_queue_policy" "order_analytics_main_policy" {
  queue_url = aws_sqs_queue.order_analytics_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.order_analytics_main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_analytics.arn
          }
        }
      }
    ]
  })
}
