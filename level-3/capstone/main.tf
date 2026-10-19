
# main.tf — Capstone: Full System

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ===== Variables =====
variable "ssh_allowed_cidr" {
  description = "IP publica autorizada para SSH, en formato CIDR (ejemplo: 203.0.113.10/32)"
  type        = string
}

# ===== VPC =====
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "bootcamp-capstone" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = { Name = "capstone-public" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "capstone-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = { Name = "capstone-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ===== Security Group =====
resource "aws_security_group" "backend_sg" {
  name        = "capstone-backend"
  description = "Backend: SSH restringido y HTTP en puerto 8080"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH desde la IP autorizada"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "Acceso al backend"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "capstone-backend" }
}

# ===== AMI Ubuntu =====
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ===== SSH Key Pair =====
resource "aws_key_pair" "capstone" {
  key_name   = "capstone-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519.pub"))
}

# ===== EC2 Backend =====
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  key_name               = aws_key_pair.capstone.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -qq
    apt-get install -y -qq docker.io
    systemctl enable --now docker
    docker run -d --name backend -p 8080:8080 \
      --restart unless-stopped \
      python:3-slim sh -c "mkdir -p /app/data && echo 'Backend running' > /app/data/status && cd /app && python3 -m http.server 8080"
  EOF

  tags = { Name = "capstone-backend" }
}

# ===== S3 =====
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "storage" {
  bucket = "bootcamp-capstone-${random_id.suffix.hex}"

  tags = { Name = "Capstone Storage" }
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===== IAM =====
resource "aws_iam_user" "app" {
  name = "capstone-app"
}

resource "aws_iam_policy" "app_s3" {
  name        = "capstone-app-s3"
  description = "Allow app to read/write objects in the capstone bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.storage.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.storage.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "app_s3" {
  user       = aws_iam_user.app.name
  policy_arn = aws_iam_policy.app_s3.arn
}

resource "aws_iam_access_key" "app" {
  user = aws_iam_user.app.name
}

# ===== Outputs =====
output "backend_public_ip" {
  value = aws_instance.backend.public_ip
}

output "bucket_name" {
  value = aws_s3_bucket.storage.bucket
}

output "app_access_key" {
  value     = aws_iam_access_key.app.id
  sensitive = true
}

output "app_secret_key" {
  value     = aws_iam_access_key.app.secret
  sensitive = true
}
