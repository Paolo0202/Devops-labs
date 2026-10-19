
#!/bin/bash
# ===================================================
# 05-capstone.sh — Full System Integration
# ===================================================
# Terraform + AWS + k3s + S3 + diagnostico IAM
# IMPORTANTE: ejecutar puede crear recursos con costo en AWS.

set -euo pipefail

echo "=================================="
echo "  CAPSTONE: FULL SYSTEM"
echo "=================================="

# ---- 0. Verificar prerequisitos ----
echo "Verificando herramientas..."

for cmd in terraform kubectl aws docker curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: falta instalar $cmd"
    exit 1
  fi
done

aws sts get-caller-identity >/dev/null
echo "Prerequisitos OK"

# ---- Rutas del proyecto ----
CAP_DIR="$HOME/Devops-labs/level-3/capstone"
APP_DIR="$HOME/Devops-labs/level-3/app"
RUN_DIR="$HOME/Devops-labs/level-3/labs/.run"

mkdir -p "$RUN_DIR"

if [[ ! -f "$CAP_DIR/main.tf" ]]; then
  echo "ERROR: no se encuentra $CAP_DIR/main.tf"
  exit 1
fi

# ---- 1. Terraform ----
echo "Preparando infraestructura AWS..."
cd "$CAP_DIR"

terraform init
terraform apply --auto-approve

BACKEND_IP=$(terraform output -raw backend_public_ip)
BUCKET_NAME=$(terraform output -raw bucket_name)
APP_AK=$(terraform output -raw app_access_key)
APP_SK=$(terraform output -raw app_secret_key)

echo "Infraestructura preparada"
echo "Backend: http://$BACKEND_IP:8080"
echo "Bucket: s3://$BUCKET_NAME"

# ---- 2. Crear Secret de Kubernetes ----
echo "Configurando credenciales..."

kubectl create secret generic aws-creds \
  --from-literal=access-key-id="$APP_AK" \
  --from-literal=secret-access-key="$APP_SK" \
  --from-literal=bucket="$BUCKET_NAME" \
  --from-literal=backend-url="http://$BACKEND_IP:8080" \
  --dry-run=client -o yaml | kubectl apply -f -

# ---- 3. Construir imagen y desplegar ----
echo "Construyendo imagen..."

cd "$APP_DIR"
docker build --network=host -t flask-app:latest .

cat > "$CAP_DIR/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-s3-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask-s3
  template:
    metadata:
      labels:
        app: flask-s3
    spec:
      containers:
      - name: flask
        image: flask-app:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5001
        env:
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: aws-creds
              key: access-key-id
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: aws-creds
              key: secret-access-key
        - name: S3_BUCKET
          valueFrom:
            secretKeyRef:
              name: aws-creds
              key: bucket
        - name: BACKEND_URL
          valueFrom:
            secretKeyRef:
              name: aws-creds
              key: backend-url
        - name: S3_ENDPOINT
          value: "https://s3.amazonaws.com"
---
apiVersion: v1
kind: Service
metadata:
  name: flask-s3-app
spec:
  selector:
    app: flask-s3
  ports:
  - port: 5001
    targetPort: 5001
  type: NodePort
EOF

kubectl apply -f "$CAP_DIR/deployment.yaml"
kubectl rollout status deployment/flask-s3-app --timeout=120s

NODE_PORT=$(kubectl get svc flask-s3-app \
  -o jsonpath='{.spec.ports[0].nodePort}')

echo "Aplicacion: http://localhost:$NODE_PORT"

# ---- 4. Verificar y subir archivo ----
echo "Verificando aplicacion..."
sleep 5

curl -fsS "http://localhost:$NODE_PORT/health" | jq

echo '{"capstone":"ok"}' > "$RUN_DIR/capstone-test.json"

curl -fsS \
  -F "file=@$RUN_DIR/capstone-test.json" \
  "http://localhost:$NODE_PORT/" >/dev/null

curl -fsS "http://localhost:$NODE_PORT/" | grep -o 'capstone-test' || true

# ---- 5. Simular fallo y recuperar permisos ----
echo "Simulacion de fallo IAM"

ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
POLICY_ARN="arn:aws:iam::${ACCOUNT}:policy/capstone-app-s3"

# Si algo falla luego de quitar la policy, intentar restaurarla.
restore_policy() {
  aws iam attach-user-policy \
    --user-name capstone-app \
    --policy-arn "$POLICY_ARN" >/dev/null 2>&1 || true
}
trap restore_policy EXIT

aws iam detach-user-policy \
  --user-name capstone-app \
  --policy-arn "$POLICY_ARN"

echo "Policy removida temporalmente"
sleep 3

echo "Diagnostico:"
curl -s "http://localhost:$NODE_PORT/health" | jq || true

aws iam list-attached-user-policies \
  --user-name capstone-app

echo "Restaurando policy..."
aws iam attach-user-policy \
  --user-name capstone-app \
  --policy-arn "$POLICY_ARN"

sleep 10

echo "Resultado despues de restaurar:"
curl -s "http://localhost:$NODE_PORT/health" | jq || true

trap - EXIT

echo "=================================="
echo "CAPSTONE COMPLETADO"
echo "=================================="
echo "Limpieza manual, cuando corresponda:"
echo "kubectl delete deployment flask-s3-app"
echo "kubectl delete svc flask-s3-app"
echo "kubectl delete secret aws-creds"
echo "cd $CAP_DIR && terraform destroy"
