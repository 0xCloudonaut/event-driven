############################## Payment Processing Queue ##############################

resource "aws_sqs_queue" "payment_processing_dlq" {
  name                      = var.payment_processing_dlq_name
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "payment_processing_main" {
  name                       = var.payment_processing_queue_name
  message_retention_seconds  = 86400
  visibility_timeout_seconds = aws_lambda_function.process_payment_lambda.timeout * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.payment_processing_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "payment_processing_main_policy" {
  queue_url = aws_sqs_queue.payment_processing_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSnsSendMessageToPaymentProcessingQueue"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.payment_processing_main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.payment_processing_topic.arn
          }
        }
      }
    ]
  })
}

############################## Inventory Management Queue ##############################

resource "aws_sqs_queue" "inventory_management_dlq" {
  name                      = var.inventory_management_dlq_name
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "inventory_management_main" {
  name                       = var.inventory_management_main_queue_name
  message_retention_seconds  = 86400
  visibility_timeout_seconds = aws_lambda_function.inventory_management.timeout * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.inventory_management_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "inventory_management_main_policy" {
  queue_url = aws_sqs_queue.inventory_management_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSnsSendMessageToInventoryManagementQueue"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.inventory_management_main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_place_topic.arn
          }
        }
      }
    ]
  })
}

############################## Notification Queue ##############################

resource "aws_sqs_queue" "notification_dlq" {
  name                      = var.notification_dlq_name
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "notification_main" {
  name                       = var.notification_main_queue_name
  message_retention_seconds  = 86400
  visibility_timeout_seconds = aws_lambda_function.notification_lambda.timeout * 6

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_policy" "notification_main_policy" {
  queue_url = aws_sqs_queue.notification_main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSnsSendMessageToNotificationQueue"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action   = "SQS:SendMessage"
        Resource = aws_sqs_queue.notification_main.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.order_place_topic.arn
          }
        }
      }
    ]
  })
}