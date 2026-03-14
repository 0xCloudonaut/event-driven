# creating standard SNS topics for order placing event
resource "aws_sns_topic" "order_place_topic" {
  name = "order_place_topic"
}

# Creating an sns subscription for order processing queue
resource "aws_sns_topic_subscription" "order_processing_queue_subscription" {
  topic_arn = aws_sns_topic.order_place_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_processing_queue.arn
}

# creating an sns subscription for order analytics queue
resource "aws_sns_topic_subscription" "order_analytics_queue_subscription" {
  topic_arn = aws_sns_topic.order_place_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_analytics_queue.arn
}