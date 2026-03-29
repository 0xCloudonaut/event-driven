//////////////////////// Order-Placement Topic ////////////////////////

# SNS topic that receives new order events from API Gateway -> Lambda.
resource "aws_sns_topic" "order_place_topic" {
  name = var.sns_order_place_topic_name
}

 // Event source mapping and fan out to the inventory management function
# Fan out order events to the processing queue.
resource "aws_sns_topic_subscription" "inventory_management_queue_subscription" {
  topic_arn = aws_sns_topic.order_place_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.inventory_management_main.arn
}

# Creating aws lambda event source mapping for inventory management function
resource "aws_lambda_event_source_mapping" "inventory_management_event" {
  event_source_arn = aws_sns_topic.order_place_topic.arn
  function_name    = aws_lambda_function.inventory_management.arn
}

  // Event source mapping and fan out to the notification function
# Fan out the same order events to the analytics queue.
resource "aws_sns_topic_subscription" "notification_main_queue_subscription" {
  topic_arn = aws_sns_topic.order_place_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.notification_main.arn
}

# Creating aws lambda event source mapping for notification function
resource "aws_lambda_event_source_mapping" "notification_event" {
  event_source_arn = aws_sns_topic.order_place_topic.arn
  function_name    = aws_lambda_function.notification_lambda.arn
}
