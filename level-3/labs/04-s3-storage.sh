
#!/bin/bash
# ===================================================
# 04-s3-storage.sh — S3 + Flask App
# Adaptado para Moto en localhost:5000
# ===================================================

set -euo pipefail

cd "$HOME/Devops-labs"

ENDPOINT="http://localhost:5000"
BUCKET="devops-bootcamp-1792292801"
TEST_FILE="$HOME/Devops-labs/level-3/labs/.run/level3.json"

echo "=================================="
echo "  S3 + FLASK STORAGE"
echo "=================================="
echo ""

# 1. Verificar Moto
echo "Verificando Moto S3..."
if ! curl -s "$ENDPOINT/" >/dev/null; then
  echo "ERROR: Moto no responde en $ENDPOINT"
  exit 1
fi
echo "Moto responde."
echo ""

# 2. Verificar bucket
echo "Verificando bucket..."
if ! aws --endpoint-url="$ENDPOINT" s3 ls "s3://$BUCKET" >/dev/null 2>&1; then
  echo "ERROR: No se encuentra el bucket $BUCKET"
  exit 1
fi
echo "Bucket disponible: $BUCKET"
echo ""

# 3. Crear y subir archivo de prueba
echo "Creando archivo JSON..."
mkdir -p "$(dirname "$TEST_FILE")"
echo '{"framework":"devops-bootcamp","level":3}' > "$TEST_FILE"

echo "Subiendo archivo..."
aws --endpoint-url="$ENDPOINT" s3 cp "$TEST_FILE" "s3://$BUCKET/config/level3.json"

echo "Objetos del bucket:"
aws --endpoint-url="$ENDPOINT" s3 ls "s3://$BUCKET/" --recursive
echo ""

# 4. Verificar lectura
echo "Verificando lectura del objeto..."
aws --endpoint-url="$ENDPOINT" s3 cp "s3://$BUCKET/config/level3.json" /tmp/level3-descargado.json
cat /tmp/level3-descargado.json
echo ""
echo "Lectura correcta."
echo ""

# 5. Verificar Flask
echo "Verificando Flask..."
if curl -fsS http://localhost:5001/health; then
  echo ""
  echo "Flask responde correctamente."
else
  echo ""
  echo "AVISO: Flask no responde en el puerto 5001."
  echo "Si está detenido, iniciá la aplicación desde otra terminal."
fi

echo ""
echo "=================================="
echo "  LABORATORIO S3 COMPLETADO"
echo "=================================="
