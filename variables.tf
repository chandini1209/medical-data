################################################################################
# Input Variables
################################################################################

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "medical-data-pipeline"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for data storage (must be globally unique)"
  type        = string
  default     = "medical-data-2026-23"
}

variable "glue_database_name" {
  description = "AWS Glue database name"
  type        = string
  default     = "medical_data_db"
}

variable "glue_table_name" {
  description = "AWS Glue table name"
  type        = string
  default     = "medical_records"
}

variable "lambda_image_tag" {
  description = "Docker image tag for Lambda functions (set by CI/CD or use 'latest')"
  type        = string
  default     = "latest"
}

variable "lambda_memory_size" {
  description = "Memory allocation for Lambda functions (MB)"
  type        = number
  default     = 512
  
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "Lambda memory must be between 128 and 10240 MB."
  }
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions (seconds)"
  type        = number
  default     = 300
  
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "Lambda timeout must be between 1 and 900 seconds."
  }
}
