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

variable "key_name" {
    description = "Name of the EC2 key pair to attach to worker nodes (leave empty to not set)"
    type        = string
    default     = ""
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

variable "place_order_function_name" {
  description = "Lambda function name for the API-facing order publisher."
  type        = string
  default     = "place-order"
}

variable "process_order_function_name" {
  description = "Lambda function name for the DynamoDB writer."
  type        = string
  default     = "process-order"
}

variable "analytics_function_name" {
  description = "Lambda function name for the analytics processor."
  type        = string
  default     = "analytics"
}

variable "place_order_zip_path" {
  description = "Path to the packaged deployment artifact for the place-order Lambda."
  type        = string
  default     = "../place_order.zip"
}

variable "process_order_zip_path" {
  description = "Path to the packaged deployment artifact for the process-order Lambda."
  type        = string
  default     = "../process_order.zip"
}

variable "analytics_zip_path" {
  description = "Path to the packaged deployment artifact for the analytics Lambda."
  type        = string
  default     = "../analytics.zip"
}

variable "sns_topic_name" {
  description = "SNS topic name for new order events."
  type        = string
  default     = "order-place-topic"
}

variable "order_processing_queue_name" {
  description = "Primary SQS queue name for order processing."
  type        = string
  default     = "order-processing-queue"
}

variable "order_processing_dlq_name" {
  description = "Dead-letter queue name for order processing."
  type        = string
  default     = "order-processing-dlq"
}

variable "analytics_queue_name" {
  description = "Primary SQS queue name for analytics."
  type        = string
  default     = "analytics-queue"
}

variable "analytics_dlq_name" {
  description = "Dead-letter queue name for analytics."
  type        = string
  default     = "analytics-dlq"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name used to store processed orders."
  type        = string
  default     = "orders"
}

variable "api_gateway_name" {
  description = "API Gateway REST API name for order placement."
  type        = string
  default     = "order_place_api"
}
