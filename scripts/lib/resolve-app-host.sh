#!/usr/bin/env bash
# CreativePOS — Resolve APP_HOST / APP_URL dari argumen, file konfigurasi, atau auto-detect.
#
# Usage:
#   source scripts/lib/resolve-app-host.sh
#   resolve_app_host ROOT [CLI_HOST] [CLI_PORT]
#
# Output (exported):
#   RESOLVED_HOST, RESOLVED_PORT, RESOLVED_SCHEME, RESOLVED_URL, RESOLVED_SOURCE

resolve_app_host() {
  local root="${1:?ROOT required}"
  local cli_host="${2:-}"
  local cli_port="${3:-}"

  RESOLVED_HOST=""
  RESOLVED_PORT=""
  RESOLVED_SCHEME="http"
  RESOLVED_URL=""
  RESOLVED_SOURCE=""

  local docker_env="$root/docker/.env"
  local backend_env="$root/backend/.env"

  _read_env() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 1
    grep -E "^${key}=" "$file" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '\r"' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  }

  _is_placeholder_host() {
    local h
    h="$(echo "${1,,}" | sed 's/^https\?:\/\///;s/\/.*//;s/:.*//')"
    case "$h" in
      ""|localhost|127.0.0.1|0.0.0.0|192.168.1.50|example.com|pos.example.com) return 0 ;;
      *) return 1 ;;
    esac
  }

  _parse_url() {
    local url="$1"
    local scheme host port

    [[ "$url" =~ ^(https?)://([^/:]+)(:([0-9]+))? ]] || return 1
    scheme="${BASH_REMATCH[1]}"
    host="${BASH_REMATCH[2]}"
    port="${BASH_REMATCH[4]:-}"

    if [[ -z "$port" ]]; then
      if [[ "$scheme" == "https" ]]; then port="443"; else port="80"; fi
    fi

    RESOLVED_SCHEME="$scheme"
    RESOLVED_HOST="$host"
    RESOLVED_PORT="$port"
    return 0
  }

  _build_url() {
    local scheme="$1" host="$2" port="$3"
    if [[ "$scheme" == "https" && "$port" == "443" ]]; then
      echo "https://${host}"
    elif [[ "$scheme" == "http" && "$port" == "80" ]]; then
      echo "http://${host}"
    else
      echo "${scheme}://${host}:${port}"
    fi
  }

  _detect_lan_ip() {
    local iface ip

    if command -v ip >/dev/null 2>&1; then
      iface="$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i <= NF; i++) if ($i == "dev") { print $(i + 1); exit }}')"
      if [[ -n "$iface" && "$iface" != "lo" ]]; then
        ip="$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / { split($2, a, "/"); print a[1]; exit }')"
        if [[ -n "$ip" && "$ip" != "127.0.0.1" ]]; then
          echo "$ip"
          return 0
        fi
      fi

      ip="$(ip -4 addr show 2>/dev/null | awk '
        /inet / {
          split($2, a, "/"); ip = a[1]
          if (ip ~ /^127\./ || ip ~ /^169\.254\./) next
          if ($0 ~ /docker|br-|veth|virbr|tun|tap/) next
          print ip; exit
        }')"
      if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
      fi
    fi

    if command -v hostname >/dev/null 2>&1; then
      ip="$(hostname -I 2>/dev/null | awk '{
        for (i = 1; i <= NF; i++) {
          if ($i !~ /^127\./ && $i !~ /^169\.254\./ && $i !~ /^172\.(1[6-9]|2[0-9]|3[0-1])\./) {
            print $i; exit
          }
        }
      }')"
      if [[ -n "$ip" ]]; then
        echo "$ip"
        return 0
      fi
    fi

    return 1
  }

  _detect_fqdn() {
    local fqdn
    fqdn="$(hostname -f 2>/dev/null || true)"
    if [[ -n "$fqdn" && "$fqdn" != "localhost" && "$fqdn" != "(none)" ]]; then
      if ! _is_placeholder_host "$fqdn"; then
        echo "$fqdn"
        return 0
      fi
    fi
    return 1
  }

  _finalize() {
    RESOLVED_URL="$(_build_url "$RESOLVED_SCHEME" "$RESOLVED_HOST" "$RESOLVED_PORT")"
    export RESOLVED_HOST RESOLVED_PORT RESOLVED_SCHEME RESOLVED_URL RESOLVED_SOURCE
  }

  # 1) Argumen CLI
  if [[ -n "$cli_host" ]]; then
    RESOLVED_HOST="$cli_host"
    RESOLVED_PORT="${cli_port:-80}"
    RESOLVED_SCHEME="http"
    RESOLVED_SOURCE="argumen CLI"
    _finalize
    return 0
  fi

  # 2) docker/.env → APP_HOST (+ APP_PORT)
  local docker_host docker_port
  docker_host="$(_read_env "$docker_env" APP_HOST || true)"
  docker_port="$(_read_env "$docker_env" APP_PORT || true)"

  if [[ -n "$docker_host" ]] && ! _is_placeholder_host "$docker_host"; then
    RESOLVED_HOST="$docker_host"
    RESOLVED_PORT="${docker_port:-${cli_port:-80}}"
    RESOLVED_SCHEME="http"
    RESOLVED_SOURCE="docker/.env (APP_HOST)"
    _finalize
    return 0
  fi

  # 3) backend/.env → APP_URL atau FRONTEND_URL
  local app_url frontend_url
  app_url="$(_read_env "$backend_env" APP_URL || true)"
  frontend_url="$(_read_env "$backend_env" FRONTEND_URL || true)"

  if [[ -n "$app_url" ]] && _parse_url "$app_url"; then
    if ! _is_placeholder_host "$RESOLVED_HOST"; then
      if [[ -n "$cli_port" ]]; then
        RESOLVED_PORT="$cli_port"
      elif [[ -n "$docker_port" ]]; then
        RESOLVED_PORT="$docker_port"
      elif [[ "$RESOLVED_PORT" == "8000" || "$RESOLVED_PORT" == "3000" || "$RESOLVED_PORT" == "8080" ]]; then
        RESOLVED_PORT="80"
      fi
      RESOLVED_SOURCE="backend/.env (APP_URL)"
      _finalize
      return 0
    fi
  fi

  if [[ -n "$frontend_url" ]] && _parse_url "$frontend_url"; then
    if ! _is_placeholder_host "$RESOLVED_HOST"; then
      if [[ -n "$cli_port" ]]; then
        RESOLVED_PORT="$cli_port"
      elif [[ -n "$docker_port" ]]; then
        RESOLVED_PORT="$docker_port"
      elif [[ "$RESOLVED_PORT" == "8000" || "$RESOLVED_PORT" == "3000" || "$RESOLVED_PORT" == "8080" ]]; then
        RESOLVED_PORT="80"
      fi
      RESOLVED_SOURCE="backend/.env (FRONTEND_URL)"
      _finalize
      return 0
    fi
  fi

  # 4) Auto-detect IP LAN (interface default route)
  local detected_ip
  if detected_ip="$(_detect_lan_ip)"; then
    RESOLVED_HOST="$detected_ip"
    RESOLVED_PORT="${docker_port:-${cli_port:-80}}"
    RESOLVED_SCHEME="http"
    RESOLVED_SOURCE="auto-detect IP LAN"
    _finalize
    return 0
  fi

  # 5) FQDN / hostname
  local fqdn
  if fqdn="$(_detect_fqdn)"; then
    RESOLVED_HOST="$fqdn"
    RESOLVED_PORT="${docker_port:-${cli_port:-80}}"
    RESOLVED_SCHEME="http"
    RESOLVED_SOURCE="hostname (FQDN)"
    _finalize
    return 0
  fi

  # 6) Prompt manual (kecuali CREATIVEPOS_NO_PROMPT=1)
  if [[ "${CREATIVEPOS_NO_PROMPT:-0}" != "1" ]]; then
    read -rp "Masukkan IP/hostname server: " RESOLVED_HOST
    RESOLVED_PORT="${docker_port:-${cli_port:-80}}"
    RESOLVED_SCHEME="http"
    RESOLVED_SOURCE="input manual"
    _finalize
    return 0
  fi

  echo "Gagal mendeteksi APP_HOST. Set manual: bash install.sh IP_SERVER" >&2
  return 1
}