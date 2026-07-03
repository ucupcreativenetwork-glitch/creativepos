#!/usr/bin/env bash
# Generate secrets in host .env files (must run BEFORE docker compose up).
#
# Usage:
#   source scripts/lib/generate-env.sh
#   ensure_openssl
#   ensure_app_key "$ROOT/backend/.env"

ensure_openssl() {
  if command -v openssl >/dev/null 2>&1; then
    return 0
  fi
  echo "openssl belum terinstall — diperlukan untuk generate APP_KEY." >&2
  if [[ "${EUID:-}" -eq 0 ]] && command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq openssl
    return 0
  fi
  echo "Pasang openssl lalu jalankan ulang install." >&2
  return 1
}

_rand_token() {
  local len="${1:-32}"
  openssl rand -base64 48 | tr -d '/+=' | head -c "$len"
}

ensure_app_key() {
  local env_file="${1:?env file required}"

  if [[ -f "$env_file" ]] && grep -qE '^APP_KEY=base64:[A-Za-z0-9+/=]{20,}' "$env_file"; then
    return 0
  fi

  ensure_openssl || return 1

  local key="base64:$(_rand_token 44)"
  if [[ -f "$env_file" ]] && grep -q '^APP_KEY=' "$env_file"; then
    sed -i "s|^APP_KEY=.*|APP_KEY=${key}|" "$env_file"
  else
    echo "APP_KEY=${key}" >>"$env_file"
  fi
  echo "APP_KEY dibuat di $(basename "$env_file") (host)."
}

ensure_reverb_keys() {
  local env_file="${1:?env file required}"
  ensure_openssl || return 1

  if ! grep -qE '^REVERB_APP_KEY=.+' "$env_file"; then
    local reverb_key
    reverb_key="$(_rand_token 20)"
    if grep -q '^REVERB_APP_KEY=' "$env_file"; then
      sed -i "s/^REVERB_APP_KEY=.*/REVERB_APP_KEY=${reverb_key}/" "$env_file"
    else
      echo "REVERB_APP_KEY=${reverb_key}" >>"$env_file"
    fi
  fi

  if ! grep -qE '^REVERB_APP_SECRET=.+' "$env_file"; then
    local reverb_secret
    reverb_secret="$(_rand_token 32)"
    if grep -q '^REVERB_APP_SECRET=' "$env_file"; then
      sed -i "s/^REVERB_APP_SECRET=.*/REVERB_APP_SECRET=${reverb_secret}/" "$env_file"
    else
      echo "REVERB_APP_SECRET=${reverb_secret}" >>"$env_file"
    fi
  fi
}