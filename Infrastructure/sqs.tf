############################## Order Processing Queue ##############################

resource "aws_sqs_queue" "order_processing_dlq" {
  name                      = "order-processing-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "order_processing_main" {
  name                       = "order-processing-queue"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = aws_lambda_function.order_processing_event.timeout * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_processing_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "order_processing_main_policy" {
  queue_url = aws_sqs_queue.order_processing_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSnsSendMessageToOrderProcessingQueue"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.order_processing_main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_place_topic.arn
          }
        }
      }
    ]
  })
}

############################## Analytics Queue ##############################

resource "aws_sqs_queue" "order_analytics_dlq" {
  name                      = "analytics-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "order_analytics_main" {
  name                       = "analytics-queue"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = aws_lambda_function.order_analytics_event.timeout * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.order_analytics_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "order_analytics_main_policy" {
  queue_url = aws_sqs_queue.order_analytics_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSnsSendMessageToAnalyticsQueue"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.order_analytics_main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_place_topic.arn
          }
        }
      }
    ]
  })
}
