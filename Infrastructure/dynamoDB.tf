# create a dynamo db for storing orders with partition key as order id and sort key as creation timestamp
resource "aws_dynamodb_table" "orders" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  hash_key  = "order_id"
  range_key = "created_at"

  tags = {
    Name = var.dynamodb_table_name
  }
}
