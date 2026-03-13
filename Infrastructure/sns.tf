# creating an SNS topic
resource "aws_sns_topic" "my_topic" {
  name = "my_topic"
}

# creating an SNS subscription
resource "aws_sns_topic_subscription" "my_subscription" {
  topic_arn = aws_sns_topic.my_topic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.my_lambda.arn
}

# creating an SNS topic policy
resource "aws_sns_topic_policy" "my_topic_policy" {
  arn = aws_sns_topic.my_topic.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.my_topic.arn
      }
    ]
  })
}