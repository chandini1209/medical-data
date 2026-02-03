# Medical Data Pipeline - AWS Serverless Infrastructure

A complete Infrastructure-as-Code solution for processing medical data using AWS serverless services. This pipeline automatically converts CSV files to Parquet format, catalogs them in AWS Glue, and enables SQL queries via Amazon Athena.

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Usage](#-usage)
- [CI/CD](#-cicd)
- [Troubleshooting](#-troubleshooting)

## 🏗️ Architecture

```
┌─────────────┐
│ CSV Upload  │
│   to S3     │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ S3: input/          │
│ (Triggers Lambda 1) │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐      ┌─────────────────┐
│ Lambda 1:           │──────▶│ ECR Repository  │
│ CSV→Parquet         │      │ (Docker Image)  │
└──────┬──────────────┘      └─────────────────┘
       │
       ▼
┌─────────────────────┐
│ S3: record_folders/ │
│ (Triggers Lambda 2) │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐      ┌─────────────────┐
│ Lambda 2:           │──────▶│ AWS Glue        │
│ Catalog Manager     │      │ Data Catalog    │
└─────────────────────┘      └─────────────────┘
                                     │
                                     ▼
┌─────────────┐      ┌─────────────────────┐
│ API Request │──────▶│ API Gateway         │
└─────────────┘      └──────┬──────────────┘
                            │
                            ▼
                     ┌─────────────────────┐      ┌─────────────────┐
                     │ Lambda 3:           │──────▶│ Amazon Athena   │
                     │ Query Executor      │      │ (SQL Queries)   │
                     └─────────────────────┘      └─────────────────┘
```

## ✨ Features

- **Serverless Architecture**: Pay only for what you use
- **Automatic Conversion**: CSV to Parquet conversion on upload
- **Data Cataloging**: Automatic AWS Glue catalog updates
- **SQL Queries**: Query data using standard SQL via Athena
- **Container-based Lambdas**: All functions deployed as Docker images in ECR
- **Infrastructure as Code**: Complete Terraform configuration
- **CI/CD Ready**: GitHub Actions and Bitbucket Pipelines included
- **Secure**: Encryption at rest, IAM roles, no public access
- **Modular**: Clean file structure for easy maintenance

## 📦 Prerequisites

### Required Tools

- [AWS CLI](https://aws.amazon.com/cli/) v2.x or later
- [Terraform](https://www.terraform.io/) v1.0 or later
- [Docker](https://www.docker.com/) v20.x or later
- Git

### AWS Account Requirements

- AWS Account with administrative access
- AWS Access Key ID and Secret Access Key
- Permissions to create:
  - S3 buckets
  - Lambda functions
  - ECR repositories
  - IAM roles and policies
  - API Gateway
  - Glue databases and tables
  - DynamoDB tables

## 📁 Project Structure

```
medical-data-pipeline/
├── main.tf                      # Terraform entry point
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── ecr.tf                       # ECR repositories
├── s3.tf                        # S3 bucket configuration
├── iam.tf                       # IAM roles and policies
├── lambda.tf                    # Lambda functions
├── api-gateway.tf               # API Gateway configuration
├── terraform.tfvars             # Your configuration (git-ignored)
├── backend.conf                 # Backend config (git-ignored)
├── .gitignore                   # Git ignore rules
├── .github/
│   └── workflows/
│       └── deploy.yml           # GitHub Actions workflow
├── bitbucket-pipelines.yml      # Bitbucket Pipelines config
└── functions/
    ├── conversion/              # CSV to Parquet Lambda
    │   ├── Dockerfile
    │   ├── lambda_function.py
    │   └── requirements.txt
    ├── glue_catalog/            # Glue Catalog Lambda
    │   ├── Dockerfile
    │   ├── lambda_function.py
    │   └── requirements.txt
    └── query/                   # Athena Query Lambda
        ├── Dockerfile
        ├── lambda_function.py
        └── requirements.txt
```

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd medical-data-pipeline
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your preferred region (e.g., eu-central-1)
# Enter output format (json)
```

### 3. Configure the Project

```bash
# Copy configuration files
cp terraform.tfvars terraform.tfvars
cp backend.conf backend.conf

# Edit the files with your values
nano terraform.tfvars
nano backend.conf
```

**Important**: Update these values in `terraform.tfvars`:
- `s3_bucket_name`: Must be globally unique!
- `aws_region`: Your preferred AWS region

### 4. Create Terraform Backend

```bash
# Set variables
BACKEND_BUCKET="your-terraform-state-bucket"
AWS_REGION="eu-central-1"

# Create S3 bucket for state
aws s3api create-bucket \
  --bucket $BACKEND_BUCKET \
  --region $AWS_REGION \
  --create-bucket-configuration LocationConstraint=$AWS_REGION

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket $BACKEND_BUCKET \
  --versioning-configuration Status=Enabled



### 5. Initialize Terraform

```bash
terraform init -backend-config=backend.conf
```

### 6. Create ECR Repositories

```bash
terraform apply -target=aws_ecr_repository.conversion_lambda \
                -target=aws_ecr_repository.glue_catalog_lambda \
                -target=aws_ecr_repository.query_lambda
```

### 7. Build and Push Docker Images

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="eu-central-1"
PROJECT_NAME="medical-data-pipeline"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push all images
for func in conversion glue_catalog query; do
  echo "Building $func..."
  docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME-${func}-lambda:latest \
    ./functions/$func
  docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME-${func}-lambda:latest
done
```

### 8. Deploy Infrastructure

```bash
# Review changes
terraform plan

# Deploy
terraform apply
```

### 9. Test the Deployment

```bash
# Get outputs
terraform output

# Test API
API_URL=$(terraform output -raw api_gateway_url)
curl "$API_URL?query=SELECT%20*%20FROM%20medical_records%20LIMIT%2010"
```

## ⚙️ Configuration

### terraform.tfvars

```hcl
aws_region         = "eu-central-1"
environment        = "production"
project_name       = "medical-data-pipeline"
s3_bucket_name     = "your-unique-bucket-name"
glue_database_name = "medical_data_db"
glue_table_name    = "medical_records"
lambda_image_tag   = "latest"
lambda_memory_size = 512
lambda_timeout     = 300
```

### backend.conf

```hcl
bucket         = "your-terraform-state-bucket"
key            = "medical-data-pipeline/terraform.tfstate"
region         = "eu-central-1"
encrypt        = true
dynamodb_table = "terraform-state-lock"
```

## 🔄 Deployment

### Manual Deployment

```bash
# Initialize
terraform init -backend-config=backend.conf

# Plan
terraform plan

# Apply
terraform apply

# Destroy (when needed)
terraform destroy
```

### Update Lambda Functions

```bash
# 1. Modify code in functions/*/lambda_function.py

# 2. Rebuild and push images
docker build -t $ECR_URL:new-tag ./functions/conversion
docker push $ECR_URL:new-tag

# 3. Update Terraform
terraform apply -var="lambda_image_tag=new-tag"
```

## 🎯 Usage

### Upload CSV File

```bash
aws s3 cp your-data.csv s3://your-bucket-name/input/your-data.csv
```

This automatically triggers:
1. CSV to Parquet conversion
2. Glue catalog update

### Query Data via API

```bash
# Basic query
curl "https://your-api-id.execute-api.region.amazonaws.com/production/query?query=SELECT%20*%20FROM%20medical_records%20LIMIT%2010"

# With jq for pretty output
curl -s "https://your-api-url/query?query=SELECT%20COUNT(*)%20FROM%20medical_records" | jq .
```

### Query Data via Athena Console

1. Open AWS Athena Console
2. Select database: `medical_data_db`
3. Run queries:

```sql
SELECT * FROM medical_records LIMIT 10;

SELECT COUNT(*) FROM medical_records;

SELECT column_name, COUNT(*) as count
FROM medical_records
GROUP BY column_name;
```

## 🔄 CI/CD

### GitHub Actions Setup

1. **Add secrets** to your repository:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`

2. **Push to repository**:
```bash
git add .
git commit -m "Initial commit"
git push origin main
```

The pipeline will automatically:
- Run Terraform plan on pull requests
- Build and push Docker images on main/develop
- Deploy infrastructure

### Bitbucket Pipelines Setup

1. **Add repository variables**:
   - `AWS_ACCESS_KEY_ID` (Secured)
   - `AWS_SECRET_ACCESS_KEY` (Secured)
   - `AWS_REGION`
   - `AWS_ACCOUNT_ID`
   - `PROJECT_NAME`

2. **Enable Pipelines** in repository settings

3. **Push to repository**:
```bash
git add .
git commit -m "Initial commit"
git push origin main
```

## 🔧 Troubleshooting

### Common Issues

**S3 Bucket Already Exists**
```bash
# Solution: Use a unique bucket name
s3_bucket_name = "medical-data-yourcompany-20260202"
```

**ECR Login Failed**
```bash
# Solution: Re-authenticate
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

**Terraform State Locked**
```bash
# Solution: Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### View Logs

```bash
# Lambda logs
aws logs tail /aws/lambda/medical-data-pipeline-conversion --follow
aws logs tail /aws/lambda/medical-data-pipeline-glue-catalog --follow
aws logs tail /aws/lambda/medical-data-pipeline-query --follow
```

## 📊 Costs

Estimated monthly costs (light usage):
- Lambda: ~$1-5
- S3: ~$0.50-2
- Athena: ~$5 per TB scanned
- ECR: ~$1
- API Gateway: ~$3.50 per million requests

**Total**: $10-20/month for moderate usage

## 🔐 Security

- ✅ S3 encryption at rest (AES-256)
- ✅ S3 versioning enabled
- ✅ Public access blocked
- ✅ IAM roles with least privilege
- ✅ VPC endpoints (optional - not included)
- ✅ CloudWatch logging enabled

## 📝 License

[Your License Here]

## 👥 Contributors

[Your Team/Company]

## 📧 Support

For issues or questions:
1. Check CloudWatch Logs
2. Review Terraform plan output
3. Consult troubleshooting section
4. Contact your DevOps team

---

**Made with ❤️ using Terraform and AWS**
