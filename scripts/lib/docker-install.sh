#!/usr/bin/env bash
# Shared Docker post-up steps for install/update scripts.

set -euo pipefail

DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.client.yml}"

dc() {
  docker compose -f "$DOCKER_COMPOSE_FILE" "$@"
}

wait_for_mysql() {
  echo "Menunggu MySQL..."
  for i in $(seq 1 60); do
    if dc exec -T mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
      echo "MySQL siap."
      return 0
    fi
    sleep 2
  done
  echo "ERROR: MySQL tidak merespons setelah 120 detik." >&2
  return 1
}

wait_for_backend() {
  echo "Menunggu backend API..."
  for i in $(seq 1 40); do
    if dc exec -T backend php artisan --version >/dev/null 2>&1; then
      echo "Backend siap."
      return 0
    fi
    sleep 3
  done
  echo "ERROR: Container backend tidak merespons." >&2
  dc ps
  return 1
}

clear_bootstrap_cache() {
  local root="$1"
  rm -f "$root/backend/bootstrap/cache/config.php" \
        "$root/backend/bootstrap/cache/routes-v7.php" \
        "$root/backend/bootstrap/cache/services.php" 2>/dev/null || true
  dc exec -T backend php artisan config:clear >/dev/null 2>&1 || true
  dc exec -T backend php artisan route:clear >/dev/null 2>&1 || true
}

run_migrate() {
  local with_seed="${1:-0}"
  echo "Menjalankan migrasi database..."
  for attempt in 1 2 3; do
    if [[ "$with_seed" == "1" ]]; then
      if dc exec -T backend php artisan migrate --seed --force; then
        return 0
      fi
    else
      if dc exec -T backend php artisan migrate --force; then
        return 0
      fi
    fi
    echo "Migrasi gagal (percobaan $attempt/3), tunggu 5 detik..."
    sleep 5
  done
  echo "ERROR: Migrasi database gagal." >&2
  dc logs --tail=80 backend
  return 1
}

cache_config_safe() {
  dc exec -T backend php artisan config:clear || true
  if ! dc exec -T backend php artisan config:cache; then
    echo "PERINGATAN: config:cache gagal — lanjut tanpa cache." >&2
    dc exec -T backend php artisan config:clear || true
  fi
  if ! dc exec -T backend php artisan route:cache; then
    echo "PERINGATAN: route:cache gagal — lanjut tanpa route cache." >&2
    dc exec -T backend php artisan route:clear || true
  fi
}

show_failed_logs() {
  echo "" >&2
  echo "=== Log container (untuk diagnosa) ===" >&2
  dc ps >&2 || true
  dc logs --tail=50 nginx >&2 || true
  dc logs --tail=50 backend >&2 || true
  dc logs --tail=50 frontend >&2 || true
  echo "Jalankan: bash scripts/diagnose-install.sh" >&2
}