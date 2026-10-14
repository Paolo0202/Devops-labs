#!/bin/bash
# ===================================================
# 03-vpc-networking.sh — VPC + Connectivity Debug
# ===================================================
# Verifica la VPC, subnets, rutas, Security Groups e instancias.
# Usa los recursos existentes del laboratorio.
# REQUIERE: AWS CLI configurado.

set -euo pipefail

echo "=================================="
echo "  VPC + NETWORKING DEBUG"
echo "=================================="
echo ""

# ---- 0. Configuracion ----
VPC_ID="vpc-03e14a786351d12ca"
PUB_SUBNET="subnet-0e3df61c5255d5a11"
PRIV_SUBNET="subnet-0c1abea832ca0ed0f"
IGW_ID="igw-0f82d8414a285a172"
RT_ID="rtb-086b879dd92d3f107"
SG_WEB="sg-09f0ab46ef2e069e8"
SG_DB="sg-0b733b13c0022451b"
INSTANCE_PUB="i-0bb58774c9ac09d97"
INSTANCE_PRIV="i-0307d40158ef8dd62"

echo "Cuenta AWS:"
aws sts get-caller-identity --query 'Account' --output text
echo ""

# ---- 1. Verificar VPC ----
echo "1. Verificando VPC..."
aws ec2 describe-vpcs \
  --vpc-ids "$VPC_ID" \
  --query 'Vpcs[*].[VpcId,CidrBlock,State]' \
  --output table

# ---- 2. Verificar subnets ----
echo ""
echo "2. Verificando subnets..."
aws ec2 describe-subnets \
  --subnet-ids "$PUB_SUBNET" "$PRIV_SUBNET" \
  --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]' \
  --output table

# ---- 3. Verificar Internet Gateway ----
echo ""
echo "3. Verificando Internet Gateway..."
aws ec2 describe-internet-gateways \
  --internet-gateway-ids "$IGW_ID" \
  --query 'InternetGateways[*].[InternetGatewayId,Attachments[0].State]' \
  --output table

# ---- 4. Verificar rutas publicas ----
echo ""
echo "4. Verificando tabla de rutas publica..."
aws ec2 describe-route-tables \
  --route-table-ids "$RT_ID" \
  --query 'RouteTables[*].Routes[*].[DestinationCidrBlock,GatewayId,State]' \
  --output table

# ---- 5. Verificar Security Groups ----
echo ""
echo "5. Verificando Security Groups..."
aws ec2 describe-security-groups \
  --group-ids "$SG_WEB" "$SG_DB" \
  --query 'SecurityGroups[*].[GroupName,GroupId,IpPermissions]' \
  --output json

# ---- 6. Verificar instancias ----
echo ""
echo "6. Verificando instancias..."
aws ec2 describe-instances \
  --instance-ids "$INSTANCE_PUB" "$INSTANCE_PRIV" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,SubnetId,PrivateIpAddress,PublicIpAddress]' \
  --output table

echo ""
echo "=================================="
echo "  VERIFICACION COMPLETADA"
echo "=================================="
