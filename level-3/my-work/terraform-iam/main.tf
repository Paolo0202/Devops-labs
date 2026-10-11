# main.tf — IAM resources con LocalStack
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  # Apuntar a LocalStack
  endpoints {
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }

  # No validar certificados (LocalStack no tiene HTTPS real)
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

# ===== IAM Resources =====

resource "aws_iam_user" "devops" {
  name = "devops-student-terraform"
}

resource "aws_iam_group" "developers" {
  name = "Developers"
}

resource "aws_iam_group_membership" "devops_in_devs" {
  name  = "devops-in-developers"
  group = aws_iam_group.developers.name
  users = [aws_iam_user.devops.name]
}

resource "aws_iam_policy" "s3_read" {
  name        = "S3ReadOnly"
  description = "Read-only access to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:ListAllMyBuckets", "s3:GetObject"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "s3_read_attach" {
  name       = "s3-read-attachment"
  groups     = [aws_iam_group.developers.name]
  policy_arn = aws_iam_policy.s3_read.arn
}
      
