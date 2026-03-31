//////////////////////// Order-Placement Topic ////////////////////////

# SNS topic that receives new order events from API Gateway -> Lambda.
resource "aws_sns_topic" "order_place_topic" {
  name = var.sns_order_place_topic_name
}

// Event source mapping and fan out to the inventory management function
# Fan out order events to the processing queue.
resource "aws_sns_topic_subscription" "inventory_management_queue_subscription" {
  topic_arn            = aws_sns_topic.order_place_topic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.inventory_management_main.arn
  depends_on           = [aws_sqs_queue_policy.inventory_management_main_policy]
  raw_message_delivery = true
}

# Creating aws lambda event source mapping for inventory management function
resource "aws_lambda_event_source_mapping" "inventory_management_event" {
  event_source_arn        = aws_sqs_queue.inventory_management_main.arn
  function_name           = aws_lambda_function.inventory_management.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

// Event source mapping and fan out to the notification function
# Fan out the same order events to the analytics queue.
resource "aws_sns_topic_subscription" "notification_main_queue_subscription" {
  topic_arn            = aws_sns_topic.order_place_topic.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.notification_main.arn
  depends_on           = [aws_sqs_queue_policy.notification_main_policy]
  raw_message_delivery = true
}

# Creating aws lambda event source mapping for notification function
resource "aws_lambda_event_source_mapping" "notification_event" {
  event_source_arn        = aws_sqs_queue.notification_main.arn
  function_name           = aws_lambda_function.notification_lambda.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}
