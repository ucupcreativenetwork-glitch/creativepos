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
SKIP_PREREQUISITES="${SKIP_PREREQUISITES:-0}"
DO_CLONE=0

usage() {
  cat <<'EOF'
CreativePOS — Install dari GitHub

Usage:
  bash install.sh [IP_SERVER] [PORT]
  bash scripts/install-from-github.sh --clone /opt/creativepos [IP] [PORT]

Tanpa IP: otomatis baca docker/.env → backend/.env → deteksi IP LAN/domain.

Opsi environment:
  GITHUB_TOKEN     Token untuk repo private (PAT classic/repo)
  GITHUB_REPO      URL git (default: creativepos official)
  SKIP_SEED=1      Lewati seed database demo
  SKIP_APK=1       Lewati unduh APK dari GitHub Releases
  SKIP_PREREQS=1   Lewati install Docker/Git (sudah terpasang)
  SKIP_PREREQUISITES=1  Lewati auto-install Docker/Git

Contoh:
  git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
  cd /opt/creativepos && sudo bash install.sh
  cd /opt/creativepos && sudo bash install.sh   # tanpa IP = auto-detect

  # Satu baris (repo public):
  curl -fsSL .../install-from-github.sh | sudo bash -s -- --clone /opt/creativepos
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

run_prerequisites() {
  if [[ "$SKIP_PREREQS" == "1" ]]; then
    echo "Lewati install prerequisites (SKIP_PREREQS=1)."
    return
  fi

  if [[ "${EUID:-}" -ne 0 ]]; then
    echo "Install Docker/Git membutuhkan sudo. Jalankan:"
    echo "  sudo bash install.sh [IP_SERVER]"
    exit 1
  fi

  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"

  if [[ -f "$script_dir/install-prerequisites.sh" ]]; then
    bash "$script_dir/install-prerequisites.sh"
  elif [[ -f "$script_dir/bootstrap-prerequisites.sh" ]]; then
    bash "$script_dir/bootstrap-prerequisites.sh"
  else
    echo "Bootstrap prerequisites..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq ca-certificates curl gnupg git lsb-release apt-transport-https
    if ! command -v docker >/dev/null 2>&1; then
      curl -fsSL https://get.docker.com | sh
    fi
    systemctl enable docker 2>/dev/null || true
    systemctl start docker 2>/dev/null || true
  fi
}

verify_prerequisites() {
  command -v git >/dev/null || { echo "Git belum terpasang."; exit 1; }
  command -v docker >/dev/null || { echo "Docker belum terpasang."; exit 1; }
  docker compose version >/dev/null 2>&1 || { echo "Docker Compose belum terpasang."; exit 1; }
}

# Prerequisites dulu (sebelum clone — butuh git & curl)
run_prerequisites
verify_prerequisites

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