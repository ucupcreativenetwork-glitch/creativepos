#!/usr/bin/env bash
# CreativePOS — Perbarui IP/domain dari file konfigurasi atau auto-detect (tanpa reinstall penuh)
# Usage: bash scripts/reconfigure-host.sh [APP_HOST] [APP_PORT]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI_HOST="${1:-}"
CLI_PORT="${2:-}"

# shellcheck source=lib/resolve-app-host.sh
source "$SCRIPT_DIR/lib/resolve-app-host.sh"
resolve_app_host "$ROOT" "$CLI_HOST" "$CLI_PORT"

APP_HOST="$RESOLVED_HOST"
APP_PORT="$RESOLVED_PORT"
APP_SCHEME="$RESOLVED_SCHEME"
APP_URL="$RESOLVED_URL"

echo ""
echo "=== Reconfigure Host ==="
echo "Host   : $APP_HOST (sumber: $RESOLVED_SOURCE)"
echo "URL    : $APP_URL"
echo ""

[[ -f "$ROOT/docker/.env" ]] || cp "$ROOT/docker/.env.example" "$ROOT/docker/.env"
sed -i "s/^APP_HOST=.*/APP_HOST=${APP_HOST}/" "$ROOT/docker/.env"
sed -i "s/^APP_PORT=.*/APP_PORT=${APP_PORT}/" "$ROOT/docker/.env"

[[ -f "$ROOT/backend/.env" ]] || { echo "backend/.env tidak ditemukan. Jalankan install dulu."; exit 1; }

sed -i "s|^APP_URL=.*|APP_URL=${APP_URL}|" "$ROOT/backend/.env"
sed -i "s|^FRONTEND_URL=.*|FRONTEND_URL=${APP_URL}|" "$ROOT/backend/.env"
sed -i "s/^SANCTUM_STATEFUL_DOMAINS=.*/SANCTUM_STATEFUL_DOMAINS=${APP_HOST},localhost,127.0.0.1/" "$ROOT/backend/.env"
sed -i "s/^REVERB_HOST=.*/REVERB_HOST=${APP_HOST}/" "$ROOT/backend/.env"
sed -i "s/^REVERB_PORT=.*/REVERB_PORT=${APP_PORT}/" "$ROOT/backend/.env"
sed -i "s/^REVERB_SCHEME=.*/REVERB_SCHEME=${APP_SCHEME}/" "$ROOT/backend/.env"

if docker compose -f "$ROOT/docker/docker-compose.client.yml" ps -q backend 2>/dev/null | grep -q .; then
  echo "Menerapkan ke container yang berjalan..."
  cd "$ROOT/docker"
  docker compose -f docker-compose.client.yml exec -T backend php artisan config:clear
  docker compose -f docker-compose.client.yml exec -T backend php artisan config:cache
  docker compose -f docker-compose.client.yml restart backend frontend nginx 2>/dev/null || \
    docker compose -f docker-compose.client.yml restart
  echo "Selesai. Akses: $APP_URL"
else
  echo "Container belum berjalan — konfigurasi file sudah diperbarui."
  echo "Jalankan: cd docker && docker compose -f docker-compose.client.yml up -d"
fi