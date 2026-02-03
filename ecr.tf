################################################################################
# Amazon ECR (Elastic Container Registry)
# Docker container repositories for Lambda functions
################################################################################

# ECR Repository for Conversion Lambda
resource "aws_ecr_repository" "conversion_lambda" {
  name                 = "${var.project_name}-conversion-lambda"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-conversion-lambda"
    Project     = var.project_name
    Environment = var.environment
    Function    = "CSV to Parquet Conversion"
  }
}

# ECR Repository for Glue Catalog Lambda
resource "aws_ecr_repository" "glue_catalog_lambda" {
  name                 = "${var.project_name}-glue-catalog-lambda"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-glue-catalog-lambda"
    Project     = var.project_name
    Environment = var.environment
    Function    = "Glue Catalog Management"
  }
}

# ECR Repository for Query Lambda
resource "aws_ecr_repository" "query_lambda" {
  name                 = "${var.project_name}-query-lambda"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-query-lambda"
    Project     = var.project_name
    Environment = var.environment
    Function    = "Athena Query Execution"
  }
}

# ECR Lifecycle Policy - Keep only the latest 5 images
resource "aws_ecr_lifecycle_policy" "lambda_lifecycle" {
  for_each = {
    conversion = aws_ecr_repository.conversion_lambda.name
    glue       = aws_ecr_repository.glue_catalog_lambda.name
    query      = aws_ecr_repository.query_lambda.name
  }

  repository = each.value

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep only the last 5 images to save storage costs"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}
