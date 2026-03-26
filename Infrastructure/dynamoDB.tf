# Create a dynamo db table for keeping track of inventory
resource "aws_dynamodb_table" "inventory" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "product_id"
    type = "S"
  }

  attribute {
    name = "warehouse_id"
    type = "S"
  }

  hash_key  = "product_id"
  range_key = "warehouse_id"

  tags = {
    Name = var.dynamodb_table_name
  }
}