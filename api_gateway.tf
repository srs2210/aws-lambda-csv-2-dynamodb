resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "${var.function_name}-serverless-api"
  description = "Terraform Serverless API"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id      = aws_api_gateway_rest_api.rest_api.id
  resource_id      = aws_api_gateway_resource.proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rest_api.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id      = aws_api_gateway_rest_api.rest_api.id
  resource_id      = aws_api_gateway_rest_api.rest_api.root_resource_id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.rest_api.invoke_arn
}

resource "aws_api_gateway_deployment" "endpoint" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  stage_name  = "test"
}

resource "aws_api_gateway_usage_plan" "myusageplan" {
  name = "${var.function_name}_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.rest_api.id
    stage  = aws_api_gateway_deployment.endpoint.stage_name
  }
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "my_key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.myusageplan.id
}