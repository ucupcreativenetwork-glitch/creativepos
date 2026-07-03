#!/usr/bin/env bash
# Clone (opsional) + instalasi penuh CreativePOS dari GitHub
#
# Instal baru (server kosong):
#   curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/scripts/install-from-github.sh | sudo bash -s -- --clone /opt/creativepos
#
# Sudah punya clone:
#   cd /opt/creativepos && sudo bash install.sh 10.110.1.15
#
# Repo private — set token dulu:
#   export GITHUB_TOKEN=ghp_xxxx
#   sudo -E bash install.sh --clone /opt/creativepos

set -euo pipefail

REPO_URL="${GITHUB_REPO:-https://github.com/ucupcreativenetwork-glitch/creativepos.git}"
INSTALL_DIR=""
APP_HOST="${1:-}"
APP_PORT="${2:-80}"
SKIP_SEED="${SKIP_SEED:-0}"
SKIP_APK="${SKIP_APK:-0}"
DO_CLONE=0

usage() {
  cat <<'EOF'
CreativePOS — Install dari GitHub

Usage:
  bash install.sh [IP_SERVER] [PORT]
  bash scripts/install-from-github.sh --clone /opt/creativepos [IP] [PORT]

Opsi environment:
  GITHUB_TOKEN     Token untuk repo private (PAT classic/repo)
  GITHUB_REPO      URL git (default: creativepos official)
  SKIP_SEED=1      Lewati seed database demo
  SKIP_APK=1       Lewati unduh APK dari GitHub Releases

Contoh:
  git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
  cd /opt/creativepos && sudo bash install.sh

  # Satu baris (repo public):
  curl -fsSL .../install-from-github.sh | sudo bash -s -- --clone /opt/creativepos 192.168.1.50
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clone)
      DO_CLONE=1
      INSTALL_DIR="${2:?Missing install dir after --clone}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$APP_HOST" ]]; then
        APP_HOST="$1"
      elif [[ "$APP_PORT" == "80" && "$1" =~ ^[0-9]+$ ]]; then
        APP_PORT="$1"
      fi
      shift
      ;;
  esac
done

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Perintah '$1' tidak ditemukan. Install dulu."; exit 1; }
}

need_cmd git
need_cmd docker
docker compose version >/dev/null 2>&1 || { echo "Docker Compose plugin belum terpasang."; exit 1; }

clone_repo() {
  local target="$1"
  if [[ -d "$target/.git" ]]; then
    echo "Repo sudah ada di $target — pull terbaru..."
    git -C "$target" pull --ff-only origin main
    return
  fi

  mkdir -p "$(dirname "$target")"
  local url="$REPO_URL"
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    url="${REPO_URL/https:\/\//https://${GITHUB_TOKEN}@}"
  fi

  echo "Meng-clone $REPO_URL → $target"
  git clone --depth 1 --branch main "$url" "$target"
}

if [[ $DO_CLONE -eq 1 ]]; then
  [[ -n "$INSTALL_DIR" ]] || { echo "Gunakan --clone /path/install"; exit 1; }
  clone_repo "$INSTALL_DIR"
  cd "$INSTALL_DIR"
else
  ROOT="$(cd "$(dirname "$0")/.." && pwd)"
  cd "$ROOT"
fi

if [[ ! -f "scripts/install-client.sh" ]]; then
  echo "Bukan folder CreativePOS. Clone dulu atau jalankan dari root repo."
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   CreativePOS — Install dari GitHub      ║"
echo "╚══════════════════════════════════════════╝"
echo "Folder : $(pwd)"
echo ""

chmod +x scripts/*.sh docker/scripts/*.sh 2>/dev/null || true

export SKIP_SEED SKIP_APK
bash scripts/install-client.sh "$APP_HOST" "$APP_PORT"

if [[ "$SKIP_APK" != "1" ]]; then
  bash scripts/install-mobile-apk.sh || echo "(APK release belum tersedia — lewati)"
fi

bash scripts/post-install.sh