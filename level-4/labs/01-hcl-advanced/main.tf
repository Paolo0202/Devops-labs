terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
  }

  s3_use_path_style = true
}

resource "aws_s3_bucket" "data" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

resource "aws_iam_user" "app" {
  name = "${local.prefix}-app-user"
  tags = local.common_tags
}
