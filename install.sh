#!/usr/bin/env bash
# CreativePOS — instalasi server dari GitHub (Linux)
# Usage:
#   git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
#   cd /opt/creativepos && sudo bash install.sh [IP_SERVER]

set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec bash "$ROOT/scripts/install-from-github.sh" "$@"