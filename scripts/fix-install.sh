#!/usr/bin/env bash
# Perbaiki instalasi CreativePOS yang gagal / error setelah deploy.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# shellcheck source=lib/docker-install.sh
source "$ROOT/scripts/lib/docker-install.sh"

echo "=== CreativePOS — Fix Install ==="

if [[ ! -f "$ROOT/docker/.env" ]]; then
  echo "Belum terinstall. Jalankan: sudo bash install.sh"
  exit 1
fi

rm -f "$ROOT/backend/bootstrap/cache/config.php" \
      "$ROOT/backend/bootstrap/cache/routes-v7.php" \
      "$ROOT/backend/bootstrap/cache/services.php" 2>/dev/null || true

export DOCKER_COMPOSE_FILE="$ROOT/docker/docker-compose.client.yml"
cd "$ROOT/docker"

echo "Rebuild container..."
dc up -d --build

wait_for_mysql
wait_for_backend

dc exec -T backend php artisan key:generate --force 2>/dev/null || true
dc exec -T backend php artisan storage:link --force 2>/dev/null || true

run_migrate 0
cache_config_safe

dc restart nginx backend frontend 2>/dev/null || true

bash "$ROOT/scripts/post-install.sh"