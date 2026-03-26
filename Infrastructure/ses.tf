# Creating SES service for lambda to send emails
resource "aws_ses_domain_identity" "example" {
  domain = "example.com"
}

resource "aws_ses_domain_dkim" "example" {
  domain = aws_ses_domain_identity.example.domain
}

resource "aws_ses_email_identity" "example" {
  email = "noreply@example.com"
}