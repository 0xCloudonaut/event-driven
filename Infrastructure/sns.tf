# SNS topic that receives new order events from API Gateway -> Lambda.
resource "aws_sns_topic" "order_place_topic" {
  name = var.sns_topic_name
}

# Fan out order events to the processing queue.
resource "aws_sns_topic_subscription" "order_processing_queue_subscription" {
  topic_arn = aws_sns_topic.order_place_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_processing_main.arn
}

# Fan out the same order events to the analytics queue.
resource "aws_sns_topic_subscription" "order_analytics_queue_subscription" {
  topic_arn = aws_sns_topic.order_place_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.order_analytics_main.arn
}
