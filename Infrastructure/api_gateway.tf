# create an api gateway with post method for order placing
resource "aws_api_gateway_rest_api" "order_place_api" {
  name        = var.api_gateway_name
  description = "API for placing orders"
  policy      = aws_iam_policy.api_gateway_lambda_invoke.arn
}

# Create a resource for the order_place_api as order 
resource "aws_api_gateway_resource" "order" {
  rest_api_id = aws_api_gateway_rest_api.order_place_api.id
  parent_id   = aws_api_gateway_rest_api.order_place_api.root_resource_id
  path_part   = "order"
}

resource "aws_api_gateway_method" "order_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_place_api.id
  resource_id   = aws_api_gateway_resource.order.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "order_post" {
  rest_api_id = aws_api_gateway_rest_api.order_place_api.id
  resource_id = aws_api_gateway_resource.order.id
  http_method = aws_api_gateway_method.order_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.process_payment_lambda.invoke_arn
}

# Creating deployment for the api gateway, configuring triggers for redeployment
resource "aws_api_gateway_deployment" "order_place_api" {
  rest_api_id = aws_api_gateway_rest_api.order_place_api.id

  depends_on = [
    aws_api_gateway_integration.order_post
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.order.id,
      aws_api_gateway_method.order_post.id,
      aws_api_gateway_integration.order_post.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

// Staging got the api-gateway
resource "aws_api_gateway_stage" "order_place_api" {
  rest_api_id = aws_api_gateway_rest_api.order_place_api.id
  stage_name  = "prod"

  deployment_id = aws_api_gateway_deployment.order_place_api.id
}