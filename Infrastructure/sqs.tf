# Creating aws sqs queue for order processing named "order_processing_queue"
resource "aws_sqs_queue" "order_processing_queue" {
  name = "order_processing_queue"
}

# creating aws sqs queue for order analytics named "order_analytics_queue"
resource "aws_sqs_queue" "order_analytics_queue" {
  name = "order_analytics_queue"
}

# create a policy to allow sns order processing topic to send message to the order processing queue
resource "aws_sqs_queue_policy" "order_processing_queue_policy" {
  queue_url = aws_sqs_queue.order_processing_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.order_processing_queue.arn
        Condition = {
          "ArnEquals" = {
            "aws:SourceArn" = aws_sns_topic.order_processing_topic.arn
          }
        }
      }
    ]
  })
}

# attach the order processing policy to the order processing queue
resource "aws_sqs_queue_policy_attachment" "order_processing_queue_policy_attachment" {
  queue_url = aws_sqs_queue.order_processing_queue.id
  policy_arn = aws_sqs_queue_policy.order_processing_queue_policy.arn
}

# create a policy to allow sns order processing topic to send message to the order analytics queue
resource "aws_sqs_queue_policy" "order_analytics_queue_policy" {
  queue_url = aws_sqs_queue.order_analytics_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "SQS:SendMessage"
        Resource = aws_sqs_queue.order_analytics_queue.arn
        Condition = {
          "ArnEquals" = {
            "aws:SourceArn" = aws_sns_topic.order_processing_topic.arn
          }
        }
      }
    ]
  })
}

# attaching the order_analytics_queue_policy to the order_analytics_queue
resource "aws_sqs_queue_policy_attachment" "order_analytics_queue_policy_attachment" {
  queue_url = aws_sqs_queue.order_analytics_queue.id
  policy_arn = aws_sqs_queue_policy.order_analytics_queue_policy.arn
}
