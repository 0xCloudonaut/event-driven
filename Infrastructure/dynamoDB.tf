// Creating a dynamo db table for keeping track of inventory

module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"

  name     = var.dynamodb_table_name
  hash_key = "product_id"

  /*
    The product_id is the primary key
    The stock is the integer attribute to keep track of the inventory
  */
  attributes = [
    {
      name = "product_id"
      type = "S"
    },
    {
      name = "stock"
      type = "N"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "staging"
  }
}