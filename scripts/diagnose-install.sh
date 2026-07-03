#!/usr/bin/env bash
# Diagnosa masalah instalasi CreativePOS di server Ubuntu.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/docker"

dc() { docker compose -f docker-compose.client.yml "$@"; }

echo "=== CreativePOS — Diagnose Install ==="
echo "Folder: $ROOT"
echo "Waktu : $(date -Iseconds 2>/dev/null || date)"
echo ""

echo "--- Sistem ---"
if [[ -f /proc/meminfo ]]; then
  awk '/MemTotal|MemAvailable|SwapTotal/ {print}' /proc/meminfo
  mem_mb="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)"
  if [[ "$mem_mb" -lt 2048 ]]; then
    echo "PERINGATAN: RAM < 2GB — build frontend butuh swap (jalankan install-prerequisites.sh)"
  fi
fi
df -h / /opt 2>/dev/null | tail -n +2 || true
echo ""

echo "--- Docker ---"
docker --version 2>/dev/null || echo "Docker TIDAK terinstall"
docker compose version 2>/dev/null || echo "Docker Compose TIDAK terinstall"
echo ""

echo "--- Konfigurasi .env ---"
if [[ -f "$ROOT/backend/.env" ]]; then
  if grep -qE '^APP_KEY=base64:[A-Za-z0-9+/=]{20,}' "$ROOT/backend/.env"; then
    echo "APP_KEY  : OK (ada di host backend/.env)"
  else
    echo "APP_KEY  : KOSONG — ini penyebab umum error login/API!"
    echo "           Perbaiki: sudo bash scripts/fix-install.sh"
  fi
  grep -E '^(APP_URL|DB_HOST|DB_DATABASE|SANCTUM_STATEFUL_DOMAINS)=' "$ROOT/backend/.env" 2>/dev/null || true
else
  echo "backend/.env TIDAK ADA"
fi
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
if curl -fsS "${APP_URL}/api/v1/health" 2>/dev/null; then
  echo ""
  echo "Health check OK"
else
  echo "Health check GAGAL → ${APP_URL}/api/v1/health"
  curl -v "${APP_URL}/api/v1/health" 2>&1 | tail -15 || true
fi
echo ""

echo "--- Backend log (30 baris terakhir) ---"
dc logs --tail=30 backend 2>/dev/null || true
echo ""

echo "--- Frontend log (20 baris terakhir) ---"
dc logs --tail=20 frontend 2>/dev/null || true
echo ""

echo "--- MySQL log (10 baris terakhir) ---"
dc logs --tail=10 mysql 2>/dev/null || true
echo ""

echo "--- Nginx log (10 baris terakhir) ---"
dc logs --tail=10 nginx 2>/dev/null || true
echo ""

echo "Perbaikan otomatis:"
echo "  cd $ROOT && sudo bash scripts/fix-install.sh"
echo "  cd $ROOT && sudo bash update.sh"