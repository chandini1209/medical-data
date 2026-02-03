################################################################################
# Amazon S3 Storage
# Data storage bucket with folders and event notifications
################################################################################

# Main data bucket
resource "aws_s3_bucket" "data_bucket" {
  bucket        = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name        = var.s3_bucket_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "data_bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data_bucket_encryption" {
  bucket = aws_s3_bucket.data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "data_bucket_pab" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create input folder for CSV uploads
resource "aws_s3_object" "input_folder" {
  bucket       = aws_s3_bucket.data_bucket.id
  key          = "input/"
  content_type = "application/x-directory"
}

# Create folder for Parquet files
resource "aws_s3_object" "record_folders_folder" {
  bucket       = aws_s3_bucket.data_bucket.id
  key          = "record_folders/"
  content_type = "application/x-directory"
}

# Create folder for Athena query results
resource "aws_s3_object" "athena_results_folder" {
  bucket       = aws_s3_bucket.data_bucket.id
  key          = "athena-results/"
  content_type = "application/x-directory"
}

# S3 Event Notifications
resource "aws_s3_bucket_notification" "csv_notification" {
  bucket = aws_s3_bucket.data_bucket.id

  # Trigger conversion Lambda when CSV file is uploaded
  lambda_function {
    lambda_function_arn = aws_lambda_function.conversion_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
    filter_suffix       = ".csv"
  }

  # Trigger Glue catalog Lambda when Parquet file is created
  lambda_function {
    lambda_function_arn = aws_lambda_function.glue_catalog_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "record_folders/"
    filter_suffix       = ".parquet"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_conversion,
    aws_lambda_permission.allow_s3_glue
  ]
}
