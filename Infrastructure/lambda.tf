locals {
  inventory_management_zip_path = "${path.module}/${var.inventory_management_zip_path}"
  process_payment_zip_path      = "${path.module}/${var.process_payment_zip_path}"
  notification_zip_path         = "${path.module}/${var.notification_zip_path}"
}

// Creating a trust policy for lambda functions
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

///////////////////////////////////// Payment processing Lambda function /////////////////////////////////////

resource "aws_lambda_function" "process_payment_lambda" {
  function_name    = "process_payment_lambda"
  runtime          = var.lambda_runtime
  handler          = "payment_lambda.lambda_handler"
  role             = aws_iam_role.process_payment_lambda_role.arn
  source_code_hash = filebase64sha256(local.process_payment_zip_path)
  filename         = local.process_payment_zip_path

  environment {
    variables = {
      ORDER_RESULTS_TOPIC_ARN = aws_sns_topic.order_place_topic.arn
      INVENTORY_TABLE         = module.dynamodb_table.dynamodb_table_id
    }
  }
}

# Creating role for lambda and attaching sns publish policy
resource "aws_iam_role" "process_payment_lambda_role" {
  name               = "process_payment_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Creating policy document for process payment lambda role to get from dynamodb table and to publish to sns topic
data "aws_iam_policy_document" "process_payment_lambda_role_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [
      module.dynamodb_table.dynamodb_table_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.order_place_topic.arn
    ]
  }
}

# Creating policy from the policy document
resource "aws_iam_policy" "process_payment_lambda_role_policy" {
  name        = "process_payment_lambda_role_policy"
  description = "Policy for process payment lambda role"
  policy      = data.aws_iam_policy_document.process_payment_lambda_role_policy_document.json
}

# Attaching the permission to fetch data from the DynamoDB table to validate inventory and to publish to SNS
resource "aws_iam_role_policy_attachment" "process_payment_lambda_role_dynamodb" {
  role       = aws_iam_role.process_payment_lambda_role.name
  policy_arn = aws_iam_policy.process_payment_lambda_role_policy.arn
}

# Attaching the premission for lambda basic execution to the role
resource "aws_iam_role_policy_attachment" "process_payment_lambda_role_basic_execution" {
  role       = aws_iam_role.process_payment_lambda_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}

# Allowing the API gateway to invoke the process payment lambda function
resource "aws_lambda_permission" "api_gateway_process_payment" {
  statement_id  = "AllowAPIGatewayInvokeProcessPayment"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_payment_lambda.arn
  principal     = "apigateway.amazonaws.com"

  # The source ARN is the API Gateway's invoke URL
  source_arn = "${aws_api_gateway_rest_api.order_place_api.execution_arn}/*/*"
}

///////////////////////////////////// Notification Lambda function /////////////////////////////////////

resource "aws_lambda_function" "notification_lambda" {
  function_name    = "notification_lambda"
  runtime          = var.lambda_runtime
  handler          = "notification_lambda.lambda_handler"
  role             = aws_iam_role.notification_lambda_role.arn
  source_code_hash = filebase64sha256(local.notification_zip_path)
  filename         = local.notification_zip_path

  environment {
    variables = {
      SENDER_EMAIL = var.ses_email_identity
    }
  }
}

# Creating a role for notification_lambda lambda function
resource "aws_iam_role" "notification_lambda_role" {
  name               = "notification_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Creating policy document for notification lambda role to send email through ses and to fetch from SQS notification queue
data "aws_iam_policy_document" "notification_lambda_role_policy_document" {
  statement {
    actions = [
      "ses:SendEmail"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.notification_main.arn
    ]
  }
}

# Creating policy from the policy document
resource "aws_iam_policy" "notification_lambda_role_policy" {
  name        = "notification_lambda_role_policy"
  description = "Policy for notification lambda role"
  policy      = data.aws_iam_policy_document.notification_lambda_role_policy_document.json
}

# Attaching the policy to the role
resource "aws_iam_role_policy_attachment" "notification_lambda_role_policy_attachment" {
  role       = aws_iam_role.notification_lambda_role.name
  policy_arn = aws_iam_policy.notification_lambda_role_policy.arn
}

# Attaching the permission for lambda basic execution to the role
resource "aws_iam_role_policy_attachment" "notification_lambda_role_basic_execution" {
  role       = aws_iam_role.notification_lambda_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}

///////////////////////////////////// Inventory Management Lambda function /////////////////////////////////////

resource "aws_lambda_function" "inventory_management" {
  function_name    = "inventory_management"
  runtime          = var.lambda_runtime
  handler          = "inventory_lambda.lambda_handler"
  role             = aws_iam_role.inventory_management_lambda_role.arn
  source_code_hash = filebase64sha256(local.inventory_management_zip_path)
  filename         = local.inventory_management_zip_path

  environment {
    variables = {
      INVENTORY_TABLE = module.dynamodb_table.dynamodb_table_id
    }
  }
}

# Creating a role for inventory management lambda function
resource "aws_iam_role" "inventory_management_lambda_role" {
  name               = "inventory_management_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# creating policy document for inventory management lambda role to access DynamoDB and SQS
data "aws_iam_policy_document" "inventory_management_lambda_role_policy_document" {
  // Allow access to DynamoDB
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      module.dynamodb_table.dynamodb_table_arn
    ]
  }

  // Adding permissions for SQS
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      aws_sqs_queue.inventory_management_main.arn
    ]
  }
}

# Creating policy from the policy document
resource "aws_iam_policy" "inventory_management_lambda_role_policy" {
  name        = "inventory_management_lambda_role_policy"
  description = "Policy for inventory management lambda role"
  policy      = data.aws_iam_policy_document.inventory_management_lambda_role_policy_document.json
}

# Attaching the policy to the role
resource "aws_iam_role_policy_attachment" "inventory_management_lambda_role_policy_attachment" {
  role       = aws_iam_role.inventory_management_lambda_role.name
  policy_arn = aws_iam_policy.inventory_management_lambda_role_policy.arn
}

# Attaching the permission for lambda basic execution to the role
resource "aws_iam_role_policy_attachment" "inventory_management_lambda_role_basic_execution" {
  role       = aws_iam_role.inventory_management_lambda_role.name
  policy_arn = aws_iam_policy.lambda_basic_execution.arn
}
