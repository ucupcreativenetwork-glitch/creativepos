#!/usr/bin/env bash
# CreativePOS — Bootstrap server Ubuntu kosong (satu baris dari GitHub)
#
# Server baru (Ubuntu 22.04+):
#   curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash -s -- 10.110.1.15
#
# Repo private:
#   export GITHUB_TOKEN=ghp_xxxx
#   curl -fsSL .../bootstrap.sh | sudo -E bash -s -- 10.110.1.15

set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Jalankan dengan sudo."
  exit 1
fi

APP_HOST="${1:-}"
APP_PORT="${2:-80}"
INSTALL_DIR="${INSTALL_DIR:-/opt/creativepos}"
REPO="${GITHUB_REPO:-https://github.com/ucupcreativenetwork-glitch/creativepos.git}"
BRANCH="${GITHUB_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/${BRANCH}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  CreativePOS Bootstrap (Ubuntu/Linux)    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

echo "[1/4] Install Docker, Git, Docker Compose..."
curl -fsSL "$RAW/scripts/install-prerequisites.sh" -o "$TMP/install-prerequisites.sh"
chmod +x "$TMP/install-prerequisites.sh"
bash "$TMP/install-prerequisites.sh"

echo "[2/4] Clone repository → $INSTALL_DIR"
URL="$REPO"
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  URL="${REPO/https:\/\//https://${GITHUB_TOKEN}@}"
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
  git -C "$INSTALL_DIR" pull --ff-only origin "$BRANCH"
else
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth 1 --branch "$BRANCH" "$URL" "$INSTALL_DIR"
fi

echo "[3/4] Install CreativePOS..."
export SKIP_PREREQS=1
cd "$INSTALL_DIR"
chmod +x install.sh scripts/*.sh 2>/dev/null || true
bash install.sh "$APP_HOST" "$APP_PORT"

echo "[4/4] Selesai."