#!/bin/bash
# ===================================================
# 00-cloud-foundations.sh — Diagnostic Toolkit
# ===================================================
# Debuggea HTTP, DNS, TCP y latencia de tu app Flask.
# Corre con la app encendida.

APP_PORT=${1:-5000}
APP_URL="http://localhost:${APP_PORT}"
PASS=0
FAIL=0
green() { printf '\033[32m✅ %s\033[0m\n' "$1"; }
red()   { printf '\033[31m❌ %s\033[0m\n' "$1"; }
blue()  { printf '\033[34m🔍 %s\033[0m\n' "$1"; }

echo "=================================="
echo "  DIAGNOSTIC TOOLKIT"
echo "  Target: ${APP_URL}"
echo "=================================="
echo ""

# ---- 1. HTTP: La app responde? ----
blue "1. HTTP — La app responde?"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}" 2>/dev/null)
if [ "${HTTP_CODE}" = "200" ]; then
  green "HTTP ${HTTP_CODE} OK"
  ((PASS++))
else
  red "HTTP ${HTTP_CODE} (esperado 200)"
  ((FAIL++))
fi

# ---- 2. HTTP: Verbose ----
blue "2. HTTP — Headers de respuesta"
curl -s -I "${APP_URL}" 2>/dev/null | head -10
echo ""

# ---- 3. DNS: Resolver localhost ----
blue "3. DNS — localhost resuelve?"
LOCAL_IP=$(dig +short localhost 2>/dev/null)
if [ "${LOCAL_IP}" = "127.0.0.1" ]; then
  green "DNS localhost → ${LOCAL_IP}"
  ((PASS++))
else
  red "Esperaba 127.0.0.1, obtuve ${LOCAL_IP}"
  ((FAIL++))
fi

# ---- 4. DNS: Resolver externo ----
blue "4. DNS — google.com resuelve?"
GOOGLE_IP=$(dig +short google.com 2>/dev/null | head -1)
if [ -n "${GOOGLE_IP}" ]; then
  green "DNS google.com → ${GOOGLE_IP}"
  ((PASS++))
else
  red "No pudo resolver google.com (sin internet?)"
  ((FAIL++))
fi

# ---- 5. TCP: Puerto en escucha? ----
blue "5. TCP — Puerto ${APP_PORT} en escucha?"
if ss -tlnp | grep -q ":${APP_PORT} "; then
  green "Puerto ${APP_PORT} LISTEN"
  ((PASS++))
else
  red "Puerto ${APP_PORT} NO está en escucha (app corriendo?)"
  ((FAIL++))
fi

# ---- 6. TCP: nc conecta? ----
blue "6. TCP — netcat conecta al puerto?"
if nc -zv localhost "${APP_PORT}" 2>&1 | grep -q succeeded; then
  green "nc conecta a localhost:${APP_PORT}"
  ((PASS++))
else
  red "nc NO puede conectar a localhost:${APP_PORT}"
  ((FAIL++))
fi

# ---- 7. Latencia: curl timing ----
blue "7. Latencia — curl timing"
CURL_TIME=$(curl -w "%{time_total}" -o /dev/null -s "${APP_URL}" 2>/dev/null)
if [ -n "${CURL_TIME}" ]; then
  echo "   ⏱️  Tiempo total: ${CURL_TIME}s"
  ((PASS++))
else
  red "No se pudo medir latencia"
  ((FAIL++))
fi

# ---- 8. Latencia: ping a Google ----
blue "8. Latencia — ping google.com"
PING_RESULT=$(ping -c 3 google.com 2>/dev/null | tail -1)
if [ -n "${PING_RESULT}" ]; then
  echo "   📡 ${PING_RESULT}"
  ((PASS++))
else
  red "No se pudo hacer ping a google.com"
  ((FAIL++))
fi

# ---- 9. Error: puerto cerrado (predictivo) ----
blue "9. 🔮 Error predictivo — ¿qué pasa si matamos Flask?"
echo "   Para probar, ejecuta:"
echo "   pkill -f 'python3 app.py'"
echo "   curl -v http://localhost:${APP_PORT}/"
echo "   → Verás: curl: (7) Connection refused"
echo "   → Significa: nada escucha en ese puerto"

echo ""
echo "=================================="
echo "  RESULTADOS"
echo "  ✅ ${PASS} pasaron"
echo "  ❌ ${FAIL} fallaron"
echo "=================================="
      
