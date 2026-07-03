#!/usr/bin/env bash
# Diagnosa masalah instalasi CreativePOS di server Ubuntu.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/docker"

dc() { docker compose -f docker-compose.client.yml "$@"; }

echo "=== CreativePOS — Diagnose Install ==="
echo "Folder: $ROOT"
echo ""

echo "--- Docker ---"
docker --version 2>/dev/null || echo "Docker TIDAK terinstall"
docker compose version 2>/dev/null || echo "Docker Compose TIDAK terinstall"
echo ""

echo "--- Container status ---"
dc ps 2>/dev/null || echo "docker compose gagal (belum install?)"
echo ""

echo "--- Port 80 ---"
if command -v ss >/dev/null; then
  ss -tlnp | grep ':80 ' || echo "Port 80 kosong / tidak listen"
elif command -v netstat >/dev/null; then
  netstat -tlnp 2>/dev/null | grep ':80 ' || true
fi
echo ""

echo "--- Health API ---"
APP_URL="$(grep -E '^APP_URL=' "$ROOT/backend/.env" 2>/dev/null | cut -d= -f2- | tr -d '\r' || true)"
if [[ -z "$APP_URL" ]]; then
  APP_HOST="$(grep -E '^APP_HOST=' "$ROOT/docker/.env" 2>/dev/null | cut -d= -f2- | tr -d '\r' || echo 127.0.0.1)"
  APP_URL="http://${APP_HOST}"
fi
curl -fsS "${APP_URL}/api/v1/health" 2>/dev/null && echo "" || echo "Health check GAGAL → $APP_URL/api/v1/health"
echo ""

echo "--- Backend log (20 baris terakhir) ---"
dc logs --tail=20 backend 2>/dev/null || true
echo ""

echo "--- Frontend log (20 baris terakhir) ---"
dc logs --tail=20 frontend 2>/dev/null || true
echo ""

echo "--- MySQL log (10 baris terakhir) ---"
dc logs --tail=10 mysql 2>/dev/null || true
echo ""

echo "Perbaikan umum:"
echo "  cd $ROOT && sudo bash scripts/fix-install.sh"
echo "  cd $ROOT && sudo bash update.sh"