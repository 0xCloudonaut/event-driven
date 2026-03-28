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
  default     = "../inventory_management.zip"
}

variable "process_payment_zip_path" {
  description = "Path to the packaged deployment artifact for the process-payment Lambda."
  type        = string
  default     = "../process_payment.zip"
}

variable "notification_zip_path" {
  description = "Path to the packaged deployment artifact for the notification Lambda."
  type        = string
  default     = "../notification.zip"
}

variable "sns_order_place_topic_name" {
  description = "SNS topic name for new order events."
  type        = string
  default     = "order-place-topic"
}

variable "payment_processing_topic_name" {
  description = "SNS topic name for payment processing events."
  type        = string
  default     = "payment-processing-topic"
}

variable "payment_processing_queue_name" {
  description = "Primary SQS queue name for payment processing."
  type        = string
  default     = "payment-processing-queue"
}

variable "payment_processing_dlq_name" {
  description = "Dead-letter queue name for payment processing."
  type        = string
  default     = "payment-processing-dlq"
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
