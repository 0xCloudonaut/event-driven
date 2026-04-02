variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "List of availability zones for the VPC."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "lambda_runtime" {
  description = "Runtime for all Lambda functions."
  type        = string
  default     = "python3.11"
}

variable "inventory_management_zip_path" {
  description = "Path to the packaged deployment artifact for the inventory management Lambda."
  type        = string
  default     = "../inventory_lambda.zip"
}

variable "process_payment_zip_path" {
  description = "Path to the packaged deployment artifact for the process-payment Lambda."
  type        = string
  default     = "../payment_lambda.zip"
}

variable "notification_zip_path" {
  description = "Path to the packaged deployment artifact for the notification Lambda."
  type        = string
  default     = "../notification_lambda.zip"
}

variable "process_payment_timeout" {
  description = "Timeout in seconds for the payment processing Lambda."
  type        = number
  default     = 10
}

variable "notification_timeout" {
  description = "Timeout in seconds for the notification Lambda."
  type        = number
  default     = 30
}

variable "inventory_management_timeout" {
  description = "Timeout in seconds for the inventory management Lambda."
  type        = number
  default     = 30
}

variable "sns_order_place_topic_name" {
  description = "SNS topic name for new order events."
  type        = string
  default     = "order-place-topic"
}

variable "inventory_management_dlq_name" {
  description = "Dead-letter queue name for inventory management."
  type        = string
  default     = "inventory-management-dlq"
}

variable "inventory_management_main_queue_name" {
  description = "Primary SQS queue name for inventory management."
  type        = string
  default     = "inventory-management-queue"
}

variable "notification_dlq_name" {
  description = "Dead-letter queue name for notifications."
  type        = string
  default     = "notification-dlq"
}

variable "notification_main_queue_name" {
  description = "Primary SQS queue name for notifications."
  type        = string
  default     = "notification-queue"
}

variable "analytics_dlq_name" {
  description = "Dead-letter queue name for analytics."
  type        = string
  default     = "analytics-dlq"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name used to store processed orders."
  type        = string
  default     = "inventory-table"
}

variable "api_gateway_name" {
  description = "API Gateway REST API name for order placement."
  type        = string
  default     = "order_place_api"
}

variable "ses_email_identity" {
  description = "Email identity for SES to send notifications."
  type        = string
  default     = "12345atharva@gmail.com"
}
