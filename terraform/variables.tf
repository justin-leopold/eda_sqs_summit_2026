# Variables for AWS API Gateway to SQS integration
# Author: justinxl

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "ansible-api-gateway-sqs-poc"
}

variable "sqs_queue_name" {
  description = "Name of the SQS queue"
  type        = string
  default     = "ansible-api-gateway-messages"
}

variable "api_gateway_name" {
  description = "Name of the API Gateway"
  type        = string
  default     = "ansible-sqs-integration-api"
}

variable "api_resource_path" {
  description = "API Gateway resource path"
  type        = string
  default     = "messages"
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "prod"
}

variable "cors_allowed_origin" {
  description = "Allowed origin for CORS headers. Use '*' for any origin or restrict to a specific domain."
  type        = string
  default     = "*"
}

variable "throttle_burst_limit" {
  description = "API Gateway throttle burst limit (max concurrent requests)"
  type        = number
  default     = 100
}

variable "throttle_rate_limit" {
  description = "API Gateway throttle rate limit (requests per second)"
  type        = number
  default     = 50
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "poc"
    Project     = "api-gateway-sqs-integration"
    ManagedBy   = "terraform"
  }
}
