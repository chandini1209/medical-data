################################################################################
# Outputs
################################################################################

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs for Lambda functions"
  value = {
    conversion  = aws_ecr_repository.conversion_lambda.repository_url
    glue        = aws_ecr_repository.glue_catalog_lambda.repository_url
    query       = aws_ecr_repository.query_lambda.repository_url
  }
}

output "ecr_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# S3 Outputs
output "s3_bucket_name" {
  description = "S3 data bucket name"
  value       = aws_s3_bucket.data_bucket.id
}

output "s3_bucket_arn" {
  description = "S3 data bucket ARN"
  value       = aws_s3_bucket.data_bucket.arn
}

output "s3_upload_command" {
  description = "Example command to upload CSV file"
  value       = "aws s3 cp your-file.csv s3://${aws_s3_bucket.data_bucket.id}/input/your-file.csv"
}

# Lambda Outputs
output "lambda_functions" {
  description = "Lambda function details"
  value = {
    conversion = {
      name = aws_lambda_function.conversion_function.function_name
      arn  = aws_lambda_function.conversion_function.arn
    }
    glue_catalog = {
      name = aws_lambda_function.glue_catalog_function.function_name
      arn  = aws_lambda_function.glue_catalog_function.arn
    }
    query = {
      name = aws_lambda_function.query_function.function_name
      arn  = aws_lambda_function.query_function.arn
    }
  }
}

# Glue Outputs
output "glue_database_name" {
  description = "Glue database name"
  value       = var.glue_database_name
}

output "glue_table_name" {
  description = "Glue table name"
  value       = var.glue_table_name
}

# API Gateway Outputs
output "api_gateway_url" {
  description = "API Gateway endpoint URL for queries"
  value       = "${aws_api_gateway_stage.query_stage.invoke_url}/query"
}

output "api_test_command" {
  description = "Example command to test API"
  value       = "curl \"${aws_api_gateway_stage.query_stage.invoke_url}/query?query=SELECT%20*%20FROM%20${var.glue_table_name}%20LIMIT%2010\""
}

# CloudWatch Logs
output "cloudwatch_log_groups" {
  description = "CloudWatch Log Groups for Lambda functions"
  value = {
    conversion   = "/aws/lambda/${aws_lambda_function.conversion_function.function_name}"
    glue_catalog = "/aws/lambda/${aws_lambda_function.glue_catalog_function.function_name}"
    query        = "/aws/lambda/${aws_lambda_function.query_function.function_name}"
  }
}
