#!/bin/bash
# ===================================================
# 01-aws-iam.sh — IAM setup + Terraform
# ===================================================
# Configura AWS CLI, LocalStack, IAM y Terraform.
# NO requiere cuenta real de AWS (todo es local).

set -euo pipefail

echo "=================================="
echo "  ☁️  IAM + LOCALSTACK + TERRAFORM"
echo "=================================="
echo ""

# ---- 1. Verificar prerequisitos ----
echo "📋 Verificando prerequisitos..."

# Docker (necesario para LocalStack)
if ! command -v docker &>/dev/null; then
  echo "❌ Docker no instalado. Completá Level 1 primero."
  exit 1
fi

# AWS CLI
if ! command -v aws &>/dev/null; then
  echo "📦 Instalando AWS CLI..."
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$HOME/Devops-labs/level-3/labs/.run/awscliv2.zip"
  unzip -q $HOME/Devops-labs/level-3/labs/.run/awscliv2.zip -d $HOME/Devops-labs/level-3/labs/.run/
  sudo $HOME/Devops-labs/level-3/labs/.run/aws/install
  rm -rf $HOME/Devops-labs/level-3/labs/.run/aws $HOME/Devops-labs/level-3/labs/.run/awscliv2.zip
fi

# jq
if ! command -v jq &>/dev/null; then
  sudo apt install -y jq
fi

# Terraform
if ! command -v terraform &>/dev/null; then
  echo "📦 Instalando Terraform..."
  wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform -y
fi

echo "✅ Prerequisitos OK"
echo ""

# ---- 2. Iniciar LocalStack ----
echo "🐳 Iniciando LocalStack..."
docker rm -f localstack 2>/dev/null || true
docker run --rm -d \
  --name localstack \
  -p 4566:4566 \
  -e SERVICES=iam,s3,ec2 \
  localstack/localstack:3

# Esperar a que esté listo
for i in $(seq 1 30); do
  if curl -s http://localhost:4566/_localstack/health | grep -q '"iam".*"running"'; then
    echo "✅ LocalStack listo (puerto 4566)"
    break
  fi
  sleep 1
done

# Configurar credenciales
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region us-east-1
aws configure set output json
echo "✅ AWS CLI configurado para LocalStack"
echo ""

# ---- 3. IAM con AWS CLI ----
echo "🔐 Creando recursos IAM..."

aws --endpoint-url=http://localhost:4566 iam create-user \
  --user-name devops-student

aws --endpoint-url=http://localhost:4566 iam create-group \
  --group-name Developers

aws --endpoint-url=http://localhost:4566 iam add-user-to-group \
  --user-name devops-student \
  --group-name Developers

aws --endpoint-url=http://localhost:4566 iam create-policy \
  --policy-name S3ReadOnly \
  --policy-document '{
    "Version":"2012-10-17",
    "Statement":[{"Effect":"Allow","Action":["s3:ListAllMyBuckets","s3:GetObject"],"Resource":"*"}]
  }'

aws --endpoint-url=http://localhost:4566 iam attach-group-policy \
  --group-name Developers \
  --policy-arn arn:aws:iam::000000000000:policy/S3ReadOnly

echo "✅ IAM resources creados"
echo ""

# ---- 4. Test de permisos ----
echo "🔍 Testeando permisos..."
AWS_AK=$(aws --endpoint-url=http://localhost:4566 iam create-access-key \
  --user-name devops-student | jq -r '.AccessKey.AccessKeyId')
AWS_SK=$(aws --endpoint-url=http://localhost:4566 iam create-access-key \
  --user-name devops-student | jq -r '.AccessKey.SecretAccessKey')

# S3 List (debería funcionar)
if AWS_ACCESS_KEY_ID="$AWS_AK" AWS_SECRET_ACCESS_KEY="$AWS_SK" \
  aws --endpoint-url=http://localhost:4566 s3 ls &>/dev/null; then
  echo "✅ s3 ls — OK (tiene permiso)"
else
  echo "❌ s3 ls — FALLÓ (debería tener permiso)"
fi

# EC2 Describe (debería fallar — AccessDenied)
if AWS_ACCESS_KEY_ID="$AWS_AK" AWS_SECRET_ACCESS_KEY="$AWS_SK" \
  aws --endpoint-url=http://localhost:4566 ec2 describe-instances 2>&1 | grep -q AccessDenied; then
  echo "✅ ec2 describe — AccessDenied (correcto, no tiene permiso)"
else
  echo "❌ ec2 describe — No falló como se esperaba"
fi

echo ""

# ---- 5. Deny explícito ----
echo "🔒 Agregando Deny explícito a DeleteBucket..."
aws --endpoint-url=http://localhost:4566 iam create-policy \
  --policy-name DenyDeleteBucket \
  --policy-document '{
    "Version":"2012-10-17",
    "Statement":[{"Effect":"Deny","Action":"s3:DeleteBucket","Resource":"*"}]
  }'

aws --endpoint-url=http://localhost:4566 iam attach-group-policy \
  --group-name Developers \
  --policy-arn arn:aws:iam::000000000000:policy/DenyDeleteBucket

# Probar
aws --endpoint-url=http://localhost:4566 s3 mb s3://test-deny 2>/dev/null
if AWS_ACCESS_KEY_ID="$AWS_AK" AWS_SECRET_ACCESS_KEY="$AWS_SK" \
  aws --endpoint-url=http://localhost:4566 s3 rb s3://test-deny --force 2>&1 | grep -q AccessDenied; then
  echo "✅ DeleteBucket bloqueado por Deny policy"
else
  echo "❌ DeleteBucket no fue bloqueado"
fi

echo ""

# ---- 6. Terraform ----
echo "🏗️  Terraform: IAM como código..."

mkdir -p $HOME/Devops-labs/level-3/labs/.run/terraform-iam-lab && cd $HOME/Devops-labs/level-3/labs/.run/terraform-iam-lab

cat > main.tf << 'TFEOF'
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
    iam = "http://localhost:4566"
    s3  = "http://localhost:4566"
  }
}

resource "aws_iam_user" "devops" {
  name = "devops-student-terraform"
}

resource "aws_iam_policy" "s3_read" {
  name        = "S3TerraformReadOnly"
  description = "Read-only access to S3 (Terraform)"

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

output "user_name" {
  value = aws_iam_user.devops.name
}

output "policy_name" {
  value = aws_iam_policy.s3_read.name
}
TFEOF

terraform init
terraform apply --auto-approve

echo ""
echo "✅ Terraform completado"
echo "📛 User creado: $(terraform output user_name)"
echo "📛 Policy creada: $(terraform output policy_name)"

# Limpiar
cd $HOME && rm -rf $HOME/Devops-labs/level-3/labs/.run/terraform-iam-lab

echo ""
echo "=================================="
echo "  ✅ LAB COMPLETADO"
echo "=================================="
      
