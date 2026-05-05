# API Gateway to SQS Integration
# Author: Justin Leopold
# Purpose: Creates an API Gateway that forwards payloads to AWS SQS queue

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source for current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# SQS Queue
resource "aws_sqs_queue" "api_gateway_queue" {
  name                      = var.sqs_queue_name
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 0
  visibility_timeout_seconds = 30

  tags = var.tags
}

# Dead Letter Queue (optional but recommended)
resource "aws_sqs_queue" "api_gateway_dlq" {
  name = "${var.sqs_queue_name}-dlq"

  tags = var.tags
}

# Redrive policy for main queue
resource "aws_sqs_queue_redrive_policy" "api_gateway_queue_redrive" {
  queue_url = aws_sqs_queue.api_gateway_queue.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.api_gateway_dlq.arn
    maxReceiveCount     = 3
  })
}

# IAM Role for API Gateway to access SQS
resource "aws_iam_role" "api_gateway_sqs_role" {
  name = "${var.project_name}-api-gateway-sqs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for API Gateway to send messages to SQS
resource "aws_iam_policy" "api_gateway_sqs_policy" {
  name        = "${var.project_name}-api-gateway-sqs-policy"
  description = "Policy for API Gateway to send messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.api_gateway_queue.arn
      }
    ]
  })

  tags = var.tags
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "api_gateway_sqs_attachment" {
  role       = aws_iam_role.api_gateway_sqs_role.name
  policy_arn = aws_iam_policy.api_gateway_sqs_policy.arn
}

# API Gateway REST API
resource "aws_api_gateway_rest_api" "sqs_api" {
  name        = var.api_gateway_name
  description = "API Gateway for SQS integration"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# API Gateway Resource
resource "aws_api_gateway_resource" "sqs_resource" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id
  parent_id   = aws_api_gateway_rest_api.sqs_api.root_resource_id
  path_part   = var.api_resource_path
}

# API Gateway Method
resource "aws_api_gateway_method" "sqs_method" {
  rest_api_id   = aws_api_gateway_rest_api.sqs_api.id
  resource_id   = aws_api_gateway_resource.sqs_resource.id
  http_method   = "POST"
  authorization = "NONE"

  request_parameters = {
    "method.request.header.Content-Type" = true
  }
}

# API Gateway Integration
resource "aws_api_gateway_integration" "sqs_integration" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id
  resource_id = aws_api_gateway_resource.sqs_resource.id
  http_method = aws_api_gateway_method.sqs_method.http_method

  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${data.aws_caller_identity.current.account_id}/${aws_sqs_queue.api_gateway_queue.name}"
  credentials             = aws_iam_role.api_gateway_sqs_role.arn

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$util.urlEncode($input.body)"
  }

  depends_on = [aws_iam_role_policy_attachment.api_gateway_sqs_attachment]
}

# API Gateway Method Response
resource "aws_api_gateway_method_response" "sqs_method_response" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id
  resource_id = aws_api_gateway_resource.sqs_resource.id
  http_method = aws_api_gateway_method.sqs_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

# API Gateway Integration Response
resource "aws_api_gateway_integration_response" "sqs_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id
  resource_id = aws_api_gateway_resource.sqs_resource.id
  http_method = aws_api_gateway_method.sqs_method.http_method
  status_code = aws_api_gateway_method_response.sqs_method_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = jsonencode({
      message = "Message sent to SQS successfully"
    })
  }

  depends_on = [aws_api_gateway_integration.sqs_integration]
}

# CORS preflight OPTIONS method
resource "aws_api_gateway_method" "sqs_options" {
  rest_api_id   = aws_api_gateway_rest_api.sqs_api.id
  resource_id   = aws_api_gateway_resource.sqs_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sqs_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id
  resource_id = aws_api_gateway_resource.sqs_resource.id
  http_method = aws_api_gateway_method.sqs_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "sqs_options_response" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id
  resource_id = aws_api_gateway_resource.sqs_resource.id
  http_method = aws_api_gateway_method.sqs_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "sqs_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id
  resource_id = aws_api_gateway_resource.sqs_resource.id
  http_method = aws_api_gateway_method.sqs_options.http_method
  status_code = aws_api_gateway_method_response.sqs_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.sqs_options_integration]
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "sqs_deployment" {
  rest_api_id = aws_api_gateway_rest_api.sqs_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.sqs_resource,
      aws_api_gateway_method.sqs_method,
      aws_api_gateway_integration.sqs_integration,
      aws_api_gateway_method.sqs_options,
      aws_api_gateway_integration.sqs_options_integration,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.sqs_method,
    aws_api_gateway_integration.sqs_integration,
    aws_api_gateway_method.sqs_options,
    aws_api_gateway_integration.sqs_options_integration,
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "sqs_stage" {
  deployment_id = aws_api_gateway_deployment.sqs_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.sqs_api.id
  stage_name    = var.api_stage_name

  tags = var.tags
}