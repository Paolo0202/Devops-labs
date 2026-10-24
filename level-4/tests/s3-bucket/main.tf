terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "bucket_name" {
  type    = string
  default = "test-bucket-tftest"
}

module "bucket" {
  source      = "../../modules/s3-bucket"
  bucket_name = var.bucket_name
}

output "bucket_name" {
  value = module.bucket.bucket_name
}
