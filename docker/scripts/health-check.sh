#!/usr/bin/env bash
# CreativePOS health check (client install)
set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-80}"

if [[ "$PORT" == "80" ]]; then
  URL="http://${HOST}/api/v1/health"
else
  URL="http://${HOST}:${PORT}/api/v1/health"
fi

echo "Checking $URL ..."
curl -fsS "$URL" | head -c 200
echo ""
echo "OK"