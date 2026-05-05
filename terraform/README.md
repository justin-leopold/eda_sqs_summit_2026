# AWS API Gateway to SQS Integration

This Terraform configuration creates an AWS API Gateway that accepts JSON payloads and forwards them to an AWS SQS queue.

## Architecture

The solution includes:
- **SQS Queue**: Main queue to receive messages from API Gateway
- **SQS Dead Letter Queue**: For handling failed message processing
- **API Gateway REST API**: Accepts POST requests with JSON payloads
- **IAM Role and Policy**: Allows API Gateway to send messages to SQS
- **CORS Support**: Includes OPTIONS method for browser compatibility

## Usage

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform >= 1.0 installed

### Deployment

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Create terraform.tfvars**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edit `terraform.tfvars` with your desired values.

3. **Plan and Apply**:
   ```bash
   terraform plan
   terraform apply
   ```

### Testing the API

After deployment, you can test the API endpoint:

```bash
# Get the API endpoint URL from Terraform outputs
API_URL=$(terraform output -raw api_gateway_invoke_url)

# Send a test message
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from API Gateway!", "timestamp": "2025-11-10T12:00:00Z"}'
```

### Consuming Messages from SQS

You can consume messages from the SQS queue using AWS CLI:

```bash
# Get the queue URL from Terraform outputs
QUEUE_URL=$(terraform output -raw sqs_queue_url)

# Receive messages
aws sqs receive-message --queue-url $QUEUE_URL
```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-west-2` |
| `project_name` | Project name for resource naming | `api-gateway-sqs-poc` |
| `sqs_queue_name` | Name of the SQS queue | `api-gateway-messages` |
| `api_gateway_name` | Name of the API Gateway | `sqs-integration-api` |
| `api_resource_path` | API Gateway resource path | `messages` |
| `api_stage_name` | API Gateway stage name | `prod` |
| `tags` | Tags to apply to all resources | See variables.tf |

### Outputs

| Output | Description |
|--------|-------------|
| `api_gateway_invoke_url` | The complete URL to send POST requests to |
| `sqs_queue_url` | SQS queue URL for message consumption |
| `sqs_queue_arn` | SQS queue ARN |
| `sqs_dlq_url` | Dead letter queue URL |

## Security Considerations

- The API Gateway endpoint is public and does not require authentication
- Consider adding API keys, request validation, or AWS WAF for production use
- IAM roles follow the principle of least privilege
- SQS queue includes a dead letter queue for error handling

## Message Format

The API accepts any valid JSON payload. Messages are stored in SQS exactly as received. Example:

```json
{
  "eventType": "user_registration",
  "userId": "12345",
  "timestamp": "2025-11-10T12:00:00Z",
  "metadata": {
    "source": "web_app",
    "version": "1.0"
  }
}
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

1. **403 Forbidden**: Check IAM role permissions and policies
2. **Message not appearing in SQS**: Verify API Gateway integration configuration
3. **CORS errors**: Ensure the OPTIONS method is properly configured

## Integration with Ansible

This infrastructure can be used as a webhook endpoint for Ansible playbooks to send job results, notifications, or trigger downstream processes.