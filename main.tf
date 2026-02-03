################################################################################
# Main Terraform Configuration
# Medical Data Pipeline - AWS Infrastructure
################################################################################

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for remote state storage
  # Configure using: terraform init -backend-config=backend.conf
  backend "s3" {
    # Values provided via backend.conf file
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
