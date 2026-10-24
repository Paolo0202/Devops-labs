variable "vpc_cidr" {
  description = "CIDR block de la VPC"
  type        = string
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${replace(var.vpc_cidr, "/", "-")}"
  }
}
