terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source   = "../modules/vpc-minimal"
  vpc_cidr = "10.10.0.0/16"
}

module "app_bucket" {
  source        = "../modules/s3-bucket"
  bucket_name   = "dev-bootcamp-app-data-ypb"
  force_destroy = false
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "bucket_name" {
  value = module.app_bucket.bucket_name
}
