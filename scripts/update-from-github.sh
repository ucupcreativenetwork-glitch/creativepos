#!/usr/bin/env bash
# Update CreativePOS dari GitHub + rebuild Docker
# Usage: cd /opt/creativepos && sudo bash scripts/update-from-github.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -d ".git" ]]; then
  echo "Folder ini bukan git repo. Clone dari GitHub dulu."
  exit 1
fi

echo "=== CreativePOS Update dari GitHub ==="
echo "Folder: $ROOT"
echo ""

git fetch origin main
git pull --ff-only origin main

chmod +x scripts/*.sh docker/scripts/*.sh 2>/dev/null || true

cd docker
echo "Membangun ulang container..."
docker compose -f docker-compose.client.yml up -d --build

echo "Menunggu MySQL..."
for i in $(seq 1 30); do
  if docker compose -f docker-compose.client.yml exec -T mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
    break
  fi
  sleep 2
done

docker compose -f docker-compose.client.yml exec -T backend php artisan migrate --force
docker compose -f docker-compose.client.yml exec -T backend php artisan config:cache
docker compose -f docker-compose.client.yml exec -T backend php artisan route:cache
docker compose -f docker-compose.client.yml exec -T backend php artisan view:cache 2>/dev/null || true

cd "$ROOT"

if [[ "${SKIP_APK:-0}" != "1" ]]; then
  bash scripts/install-mobile-apk.sh || true
fi

bash scripts/post-install.sh

echo "Update selesai."