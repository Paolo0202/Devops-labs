#!/bin/bash
# Simula trafico real hacia la app Flask

URL="http://localhost:5001"
DURATION=${1:-60}

endpoints=("/" "/health" "/nonexistent" "/presigned/test")
methods=("GET" "POST")

end=$((SECONDS + DURATION))
echo "Generando trafico por ${DURATION}s hacia $URL ..."

while [ $SECONDS -lt $end ]; do
    endpoint=${endpoints[$RANDOM % ${#endpoints[@]}]}
    method=${methods[$RANDOM % ${#methods[@]}]}

    if [ "$method" = "POST" ]; then
        curl -s -o /dev/null -X POST "$URL$endpoint"
    else
        curl -s -o /dev/null "$URL$endpoint"
    fi

    sleep $((RANDOM % 2))
done

echo "Listo. $(date)"
