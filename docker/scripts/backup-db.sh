#!/usr/bin/env bash
# Backup MySQL database from Docker client install
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$ROOT/backups}"
STAMP="$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

cd "$ROOT/docker"
docker compose -f docker-compose.client.yml exec -T mysql \
  mysqldump -u"${DB_USERNAME:-creativepos}" -p"${DB_PASSWORD:-secret}" "${DB_DATABASE:-creativepos}" \
  > "$BACKUP_DIR/creativepos_${STAMP}.sql"

echo "Backup: $BACKUP_DIR/creativepos_${STAMP}.sql"