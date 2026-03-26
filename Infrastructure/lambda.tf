locals {
  inventory_management_zip_path = "${path.module}/${var.inventory_management_zip_path}"
  process_payment_zip_path = "${path.module}/${var.process_payment_zip_path}"
  notification_zip_path     = "${path.module}/${var.notification_zip_path}"
}

///////////////////////////////////// Payment processing Lambda function /////////////////////////////////////

resource "aws_lambda_function" "process_payment_lambda" {
  function_name = "process_payment_lambda"
  runtime      = var.lambda_runtime
  handler     = "process_payment_lambda.handler"
  role       = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256(local.process_payment_zip_path)
  filename   = local.process_payment_zip_path
}

# Creating a role for process payment lambda function
resource "aws_iam_role" "process_payment_lambda_role" {
  name               = "process_payment_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Attaching permission to the process payment lambda role to push to the SNS order place topic
resource "aws_iam_policy_attachment" "process_payment_lambda_role" {
  name       = "process_payment_lambda_role"
  roles      = [aws_iam_role.process_payment_lambda_role.name]
  policy_arn = aws_iam_policy.sns_publish.arn
}

///////////////////////////////////// Notification Lambda function /////////////////////////////////////

resource "aws_lambda_function" "notification_lambda" {
  function_name = "notification_lambda"
  runtime      = var.lambda_runtime
  handler     = "notification_lambda.handler"
  role       = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256(local.notification_zip_path)
  filename   = local.notification_zip_path
}

# Creating a role for notification_lambda lambda function
resource "aws_iam_role" "notification_lambda_role" {
  name               = "notification_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Attaching the permissions to the notification_lambda_role lambda role to push to send emails through SES
resource "aws_iam_policy_attachment" "notification_lambda_role" {
  name       = "notification_lambda_role"
  roles      = [aws_iam_role.notification_lambda_role.name]
  policy_arn = aws_iam_policy.ses_send_email.arn
}

///////////////////////////////////// Inventory Management Lambda function /////////////////////////////////////

resource "aws_lambda_function" "inventory_management" {
  function_name = "inventory_management"
  runtime      = var.lambda_runtime
  handler     = "inventory_management.handler"
  role       = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256(local.inventory_management_zip_path)
  filename   = local.inventory_management_zip_path

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.orders.name
    }
  }
}

# Creating a role for inventory management lambda function
resource "aws_iam_role" "inventory_management_lambda_role" {
  name               = "inventory_management_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Attaching the permissions to the inventory management lambda role to access DynamoDB
resource "aws_iam_policy_attachment" "inventory_management_lambda_role" {
  name       = "inventory_management_lambda_role"
  roles      = [aws_iam_role.inventory_management_lambda_role.name]
  policy_arn = aws_iam_policy.dynamodb_access.arn
}