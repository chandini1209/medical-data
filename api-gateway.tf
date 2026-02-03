################################################################################
# Amazon API Gateway
# REST API for querying medical data
################################################################################

# REST API
resource "aws_api_gateway_rest_api" "query_api" {
  name        = "${var.project_name}-query-api"
  description = "API for querying medical data from Parquet files via Athena"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "${var.project_name}-query-api"
    Project     = var.project_name
    Environment = var.environment
  }
}

# /query resource
resource "aws_api_gateway_resource" "query_resource" {
  rest_api_id = aws_api_gateway_rest_api.query_api.id
  parent_id   = aws_api_gateway_rest_api.query_api.root_resource_id
  path_part   = "query"
}

# ============================================================================
# GET Method
# ============================================================================

resource "aws_api_gateway_method" "query_get" {
  rest_api_id   = aws_api_gateway_rest_api.query_api.id
  resource_id   = aws_api_gateway_resource.query_resource.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.query" = false
  }
}

resource "aws_api_gateway_integration" "query_integration" {
  rest_api_id             = aws_api_gateway_rest_api.query_api.id
  resource_id             = aws_api_gateway_resource.query_resource.id
  http_method             = aws_api_gateway_method.query_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.query_function.invoke_arn
}

# ============================================================================
# CORS - OPTIONS Method
# ============================================================================

resource "aws_api_gateway_method" "query_options" {
  rest_api_id   = aws_api_gateway_rest_api.query_api.id
  resource_id   = aws_api_gateway_resource.query_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "query_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.query_api.id
  resource_id = aws_api_gateway_resource.query_resource.id
  http_method = aws_api_gateway_method.query_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "query_options_response" {
  rest_api_id = aws_api_gateway_rest_api.query_api.id
  resource_id = aws_api_gateway_resource.query_resource.id
  http_method = aws_api_gateway_method.query_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "query_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.query_api.id
  resource_id = aws_api_gateway_resource.query_resource.id
  http_method = aws_api_gateway_method.query_options.http_method
  status_code = aws_api_gateway_method_response.query_options_response.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.query_options_response
  ]
}

# ============================================================================
# Deployment
# ============================================================================

resource "aws_api_gateway_deployment" "query_deployment" {
  rest_api_id = aws_api_gateway_rest_api.query_api.id

  depends_on = [
    aws_api_gateway_integration.query_integration,
    aws_api_gateway_integration.query_options_integration
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.query_resource.id,
      aws_api_gateway_method.query_get.id,
      aws_api_gateway_integration.query_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "query_stage" {
  deployment_id = aws_api_gateway_deployment.query_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.query_api.id
  stage_name    = var.environment

  tags = {
    Name        = var.environment
    Project     = var.project_name
    Environment = var.environment
  }
}
