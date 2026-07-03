#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/docker"

BASE="$(grep -E '^APP_URL=' ../backend/.env 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r' || true)"
if [[ -z "$BASE" ]]; then
  APP_HOST="$(grep -E '^APP_HOST=' ../docker/.env 2>/dev/null | cut -d= -f2- | tr -d '\r' || echo localhost)"
  APP_PORT="$(grep -E '^APP_PORT=' ../docker/.env 2>/dev/null | cut -d= -f2- | tr -d '\r' || echo 80)"
  if [[ "$APP_PORT" == "80" ]]; then
    BASE="http://${APP_HOST}"
  else
    BASE="http://${APP_HOST}:${APP_PORT}"
  fi
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              CreativePOS — Siap Digunakan                ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║  Web POS     : %-41s ║\n" "${BASE}/pos"
printf "║  Dashboard   : %-41s ║\n" "${BASE}/"
printf "║  Daftar      : %-41s ║\n" "${BASE}/register"
printf "║  API Health  : %-41s ║\n" "${BASE}/api/v1/health"
printf "║  APK Mobile  : %-41s ║\n" "${BASE}/api/v1/mobile/version?platform=android"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Akun default (ganti password di production!)            ║"
printf "║  Admin       : %-41s ║\n" "admin@creativepos.local"
printf "║  Password    : %-41s ║\n" "Admin123!"
printf "║  Super Admin : %-41s ║\n" "superadmin@creativepos.local"
printf "║  Password    : %-41s ║\n" "SuperAdmin123!"
printf "║  Platform    : %-41s ║\n" "${BASE}/platform"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Update      : bash scripts/update-from-github.sh        ║"
echo "║  Status      : cd docker && docker compose -f            ║"
echo "║                docker-compose.client.yml ps              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Health check
for i in $(seq 1 20); do
  if curl -fsS "${BASE}/api/v1/health" >/dev/null 2>&1; then
    echo "✓ Health check OK"
    exit 0
  fi
  sleep 3
done

echo "⚠ Health check belum OK — tunggu 1-2 menit lalu coba lagi."
exit 0