################################################################################
# AWS Lambda Functions
# Serverless compute for data processing
################################################################################

# ============================================================================
# Lambda Function 1: CSV to Parquet Conversion
# ============================================================================

resource "aws_lambda_function" "conversion_function" {
  function_name = "${var.project_name}-conversion"
  role          = aws_iam_role.conversion_lambda_role.arn
  package_type  = "Image"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  # Docker image from ECR
  image_uri = "${aws_ecr_repository.conversion_lambda.repository_url}:${var.lambda_image_tag}"

  environment {
    variables = {
      OUTPUT_BUCKET = var.s3_bucket_name
      OUTPUT_PREFIX = "record_folders"
      ENVIRONMENT   = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-conversion"
    Project     = var.project_name
    Environment = var.environment
    Function    = "CSV to Parquet Conversion"
  }
}

# Permission for S3 to invoke conversion Lambda
resource "aws_lambda_permission" "allow_s3_conversion" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.conversion_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}

# ============================================================================
# Lambda Function 2: Glue Catalog Management
# ============================================================================

resource "aws_lambda_function" "glue_catalog_function" {
  function_name = "${var.project_name}-glue-catalog"
  role          = aws_iam_role.glue_catalog_lambda_role.arn
  package_type  = "Image"
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size

  # Docker image from ECR
  image_uri = "${aws_ecr_repository.glue_catalog_lambda.repository_url}:${var.lambda_image_tag}"

  environment {
    variables = {
      GLUE_DATABASE_NAME = var.glue_database_name
      GLUE_TABLE_NAME    = var.glue_table_name
      BASE_S3_PREFIX     = "record_folders"
      ENVIRONMENT        = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-glue-catalog"
    Project     = var.project_name
    Environment = var.environment
    Function    = "Glue Catalog Management"
  }
}

# Permission for S3 to invoke Glue catalog Lambda
resource "aws_lambda_permission" "allow_s3_glue" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.glue_catalog_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_bucket.arn
}

# ============================================================================
# Lambda Function 3: Athena Query Execution
# ============================================================================

resource "aws_lambda_function" "query_function" {
  function_name = "${var.project_name}-query"
  role          = aws_iam_role.query_lambda_role.arn
  package_type  = "Image"
  timeout       = 60  # Queries typically complete faster
  memory_size   = var.lambda_memory_size

  # Docker image from ECR
  image_uri = "${aws_ecr_repository.query_lambda.repository_url}:${var.lambda_image_tag}"

  environment {
    variables = {
      DATABASE        = var.glue_database_name
      TABLE_NAME      = var.glue_table_name
      OUTPUT_LOCATION = "s3://${var.s3_bucket_name}/athena-results/"
      ENVIRONMENT     = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-query"
    Project     = var.project_name
    Environment = var.environment
    Function    = "Athena Query Execution"
  }
}

# Permission for API Gateway to invoke query Lambda
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.query_api.execution_arn}/*/*"
}
