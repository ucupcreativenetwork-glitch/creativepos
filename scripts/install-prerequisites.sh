#!/usr/bin/env bash
# CreativePOS — Auto-install Docker, Docker Compose, Git (Ubuntu/Debian)
# Usage: sudo bash scripts/install-prerequisites.sh

set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Jalankan dengan sudo: sudo bash scripts/install-prerequisites.sh"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

detect_os() {
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    echo "${ID:-unknown}"
  else
    echo "unknown"
  fi
}

OS_ID="$(detect_os)"
case "$OS_ID" in
  ubuntu|debian|linuxmint|pop)
    ;;
  *)
    echo "OS tidak didukung otomatis: $OS_ID"
    echo "Pasang manual: git, curl, Docker Engine + Compose plugin"
    exit 1
    ;;
esac

echo ""
echo "=== CreativePOS — Install Prerequisites (Linux) ==="
echo "OS: $OS_ID"
echo ""

apt-get update -qq
apt-get install -y -qq \
  ca-certificates \
  curl \
  gnupg \
  git \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  openssl

ensure_swap() {
  local mem_mb swap_mb
  mem_mb="$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 4096)"
  swap_mb="$(awk '/SwapTotal/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"

  if [[ "$mem_mb" -ge 3500 && "$swap_mb" -ge 1024 ]]; then
    return 0
  fi
  if [[ "$swap_mb" -ge 2048 ]]; then
    return 0
  fi
  if [[ -f /swapfile ]] || swapon --show 2>/dev/null | grep -q '/swapfile'; then
    return 0
  fi

  echo "RAM ${mem_mb}MB — membuat swap 2GB agar build Docker tidak gagal..."
  fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=progress
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  if ! grep -q '/swapfile' /etc/fstab 2>/dev/null; then
    echo '/swapfile none swap sw 0 0' >>/etc/fstab
  fi
  echo "Swap aktif: $(swapon --show | tail -1)"
}

ensure_swap

if ! command -v docker >/dev/null 2>&1; then
  echo "Menginstall Docker Engine + Compose plugin..."
  curl -fsSL https://get.docker.com | sh
else
  echo "Docker sudah terpasang: $(docker --version)"
fi

systemctl enable docker
systemctl start docker

if ! docker compose version >/dev/null 2>&1; then
  echo "Menginstall Docker Compose plugin..."
  apt-get install -y -qq docker-compose-plugin
fi

echo "Docker Compose: $(docker compose version)"

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
  if ! id -nG "$SUDO_USER" | grep -qw docker; then
    usermod -aG docker "$SUDO_USER"
    echo "User '$SUDO_USER' ditambahkan ke grup docker (logout/login agar aktif)."
  fi
fi

# Firewall: buka HTTP jika ufw aktif
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
  ufw allow 80/tcp comment 'CreativePOS HTTP' 2>/dev/null || true
  echo "UFW: port 80 dibuka."
fi

echo ""
echo "✓ Prerequisites siap — git, docker, docker compose"
echo ""