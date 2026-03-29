# Creating SES service for lambda to send emails

resource "aws_ses_email_identity" "example" {
  email = var.ses_email_identity
}