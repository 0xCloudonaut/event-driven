# creating a lambda function
resource "aws_lambda_function" "my_lambda" {
  function_name = "my_lambda_function"
  runtime      = "python3.8"
  role        = aws_iam_role.lambda_exec.arn
  handler     = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      foo = "bar"
    }
  }
}
