# create an api gateway with post method for order placing
resource "aws_api_gateway_rest_api" "order_place_api" {
  name        = "order_place_api"
  description = "API for placing orders"
}

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
  uri                     = aws_lambda_function.order_place_event.invoke_arn
}
