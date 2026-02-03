# ============================================================================
# Terraform Variables Configuration
# ============================================================================
# IMPORTANT: This file contains your actual configuration
# Copy terraform.tfvars.example to terraform.tfvars and update with your values
# ============================================================================

# AWS Configuration
aws_region  = "eu-central-1"  # Change to your preferred AWS region
environment = "production"     # Options: dev, staging, production

# Project Configuration
project_name = "medical-data-pipeline"

# S3 Configuration
# IMPORTANT: S3 bucket name must be globally unique across all AWS accounts
# Suggestion: use format like "company-project-env-date"
# Example: "acme-medical-data-prod-20260202"
s3_bucket_name = "medical-data-2026"  # ⚠️ CHANGE THIS!

# AWS Glue Configuration
glue_database_name = "medical_data_db"
glue_table_name    = "medical_records"

# Lambda Configuration
lambda_image_tag   = "latest"  # Will be overridden by CI/CD to use git commit SHA
lambda_memory_size = 512       # Memory in MB (128-10240)
lambda_timeout     = 300       # Timeout in seconds (1-900)
