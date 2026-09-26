#!/bin/bash

set -e

echo "▶ 1. Verificando prerequisitos..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

echo "   ✅ Docker $(docker --version | awk '{print $3}' | tr -d ',')"

# Mostrar RAM y CPUs
RAM=$(free -m | awk '/Mem:/ {print $2}')
CPUS=$(nproc)

echo "   RAM: ${RAM}MB | CPUs: ${CPUS}"

echo ""
echo "▶ 2. Instalando socat..."

sudo apt-get update
sudo apt-get install -y socat

echo ""
echo "▶ 3. Instalando k3s..."
echo "   Runtime: Docker"

curl -sfL https://get.k3s.io | sh -s - --docker

echo ""
echo "▶ 4. Iniciando k3s..."

sudo systemctl start k3s
sudo systemctl enable k3s

echo ""
echo "▶ 5. Nodos del cluster"

sudo kubectl get nodes

echo ""
echo "▶ Pods del sistema (kube-system)"

sudo kubectl get pods -n kube-system
