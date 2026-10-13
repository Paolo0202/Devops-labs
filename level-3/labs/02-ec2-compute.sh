#!/bin/bash
# ===================================================
# 02-ec2-compute.sh — EC2 + Docker + Flask
# ===================================================
# Automatiza el despliegue de Flask en AWS EC2.
# REQUIERE: AWS CLI configurado y permisos IAM adecuados.

set -euo pipefail

echo "=================================="
echo "  EC2 + DOCKER + FLASK"
echo "=================================="
echo ""

# ---- 1. Verificar AWS real ----
echo "Verificando AWS CLI..."

if ! aws sts get-caller-identity &>/dev/null; then
  echo "AWS CLI no configurado para AWS real."
  echo "Ejecuta: aws configure"
  exit 1
fi

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account: $ACCOUNT"
echo ""
# ---- 2. Security Group ----
echo "Creando Security Group..."

SG_NAME="bootcamp-web-$(date +%s)"

SG_ID=$(aws ec2 create-security-group \
  --group-name "$SG_NAME" \
  --description "Bootcamp: SSH y Flask" \
  --query 'GroupId' \
  --output text)

echo "Security Group creado: $SG_ID"

# Solicitar la IP pública actual para limitar SSH
MY_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')

echo "Tu IP pública es: $MY_IP"

aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr "$MY_IP/32"

aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 5000 \
  --cidr 0.0.0.0/0

echo "Security Group configurado."
echo ""
# ---- 3. Key Pair ----
echo "Creando Key Pair..."

KEY_NAME="bootcamp-key-$(date +%s)"
KEY_FILE="$HOME/${KEY_NAME}.pem"

aws ec2 create-key-pair \
  --key-name "$KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > "$KEY_FILE"

chmod 400 "$KEY_FILE"

echo "Key Pair creado: $KEY_NAME"
echo "Archivo de clave: $KEY_FILE"
echo ""
# ---- 4. Launch EC2 ----
echo "Buscando la imagen más reciente de Ubuntu 22.04..."

AMI=$(aws ec2 describe-images \
  --owners 099720109477 \
  --filters \
    "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
    "Name=state,Values=available" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
  --output text)

echo "AMI: $AMI"

INSTANCE_TYPE="t3.micro"
echo "Tipo de instancia: $INSTANCE_TYPE"

echo "Lanzando instancia EC2..."

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI" \
  --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" \
  --security-group-ids "$SG_ID" \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instancia creada: $INSTANCE_ID"
echo "Esperando a que esté en ejecución..."

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "Instancia lista."
echo "IP pública: $PUBLIC_IP"
echo ""
# ---- 5. SSH + Docker setup ----
echo "Instalando Docker en EC2..."

ssh \
  -o StrictHostKeyChecking=accept-new \
  -i "$KEY_FILE" \
  "ubuntu@$PUBLIC_IP" \
  "sudo apt-get update -qq && sudo apt-get install -y -qq docker.io && sudo usermod -aG docker ubuntu && sudo systemctl enable --now docker && docker --version"

echo "Docker instalado correctamente en EC2."
echo ""

# ---- 6. Build + transfer app ----
echo "Construyendo la imagen Flask..."

APP_DIR="$HOME/Devops-labs/level-1/app"
IMAGE_FILE="$HOME/Devops-labs/level-3/labs/.run/flask-app.tar.gz"

mkdir -p "$HOME/Devops-labs/level-3/labs/.run"

docker build --network host -t flask-app "$APP_DIR"

echo "Comprimiendo la imagen Docker..."
docker save flask-app | gzip > "$IMAGE_FILE"

echo "Transfiriendo la imagen a EC2..."
scp \
  -o StrictHostKeyChecking=accept-new \
  -i "$KEY_FILE" \
  "$IMAGE_FILE" \
  "ubuntu@$PUBLIC_IP:/tmp/flask-app.tar.gz"

echo "Cargando la imagen y arrancando Flask en EC2..."

ssh \
  -o StrictHostKeyChecking=accept-new \
  -i "$KEY_FILE" \
  "ubuntu@$PUBLIC_IP" \
  "gzip -dc /tmp/flask-app.tar.gz | sudo docker load && sudo docker run -d --name flask-app -p 5000:5000 flask-app"

echo "Aplicación Flask iniciada."
echo ""
# ---- 7. Test ----
echo "Probando la aplicación Flask en AWS..."
sleep 3

HTTP_CODE=$(curl -sS -o /dev/null -w "%{http_code}" \
  --max-time 10 "http://$PUBLIC_IP:5000/") || HTTP_CODE="000"

if [ "$HTTP_CODE" = "200" ]; then
  echo "Aplicación responde HTTP 200."
  echo "URL: http://$PUBLIC_IP:5000/"
else
  echo "La aplicación no respondió correctamente. HTTP: $HTTP_CODE"
  echo "Para revisar los logs:"
  echo "ssh -i \"$KEY_FILE\" ubuntu@$PUBLIC_IP"
  echo "Luego ejecuta: sudo docker logs flask-app"
fi

echo ""
echo "=================================="
echo "LAB COMPLETADO"
echo "=================================="
echo ""
echo "Instancia EC2: $INSTANCE_ID"
echo "Security Group: $SG_ID"
echo "Key Pair: $KEY_NAME"
echo "IP pública: $PUBLIC_IP"
echo ""
echo "IMPORTANTE: estos recursos pueden generar costos."
echo "No los elimines hasta terminar de verificar la práctica."
