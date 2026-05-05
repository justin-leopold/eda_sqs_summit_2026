# Outputs for AWS API Gateway to SQS integration
# Author: justinxl

output "api_gateway_invoke_url" {
  description = "Invoke URL for the API Gateway endpoint"
  value       = "${aws_api_gateway_stage.sqs_stage.invoke_url}/${var.api_resource_path}"
}

output "sqs_queue_url" {
  description = "URL of the SQS queue"
  value       = aws_sqs_queue.api_gateway_queue.url
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue"
  value       = aws_sqs_queue.api_gateway_queue.arn
}

output "sqs_dlq_url" {
  description = "URL of the SQS dead letter queue"
  value       = aws_sqs_queue.api_gateway_dlq.url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.sqs_api.id
}

output "api_gateway_arn" {
  description = "ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.sqs_api.arn
}

output "iam_role_arn" {
  description = "ARN of the IAM role used by API Gateway"
  value       = aws_iam_role.api_gateway_sqs_role.arn
}
