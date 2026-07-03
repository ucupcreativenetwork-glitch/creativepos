#!/usr/bin/env bash
# Unduh APK terbaru dari GitHub Releases dan publish ke server lokal
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${GITHUB_REPO:-ucupcreativenetwork-glitch/creativepos}"
TOKEN="${GITHUB_TOKEN:-}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

api() {
  local url="https://api.github.com/repos/${REPO}/$1"
  if [[ -n "$TOKEN" ]]; then
    curl -fsSL -H "Authorization: Bearer $TOKEN" -H "Accept: application/vnd.github+json" "$url"
  else
    curl -fsSL -H "Accept: application/vnd.github+json" "$url"
  fi
}

echo "Mencari APK di GitHub Releases ($REPO)..."

release_json="$(api releases/latest 2>/dev/null || true)"
if [[ -z "$release_json" ]]; then
  echo "Tidak ada GitHub Release — lewati publish APK."
  exit 0
fi

apk_url="$(echo "$release_json" | grep -o '"browser_download_url": *"[^"]*\.apk"' | head -1 | sed 's/.*"\(http[^"]*\)".*/\1/')"
if [[ -z "$apk_url" ]]; then
  echo "Release ada tapi tanpa file .apk — lewati."
  exit 0
fi

tag_name="$(echo "$release_json" | grep -o '"tag_name": *"[^"]*"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
version="$(echo "$tag_name" | sed 's/^v//; s/-.*//')"
build="$(echo "$tag_name" | grep -oE '[0-9]+$' || echo "1")"
apk_file="$TMP_DIR/creativepos.apk"

echo "Mengunduh $apk_url"
if [[ -n "$TOKEN" ]]; then
  curl -fsSL -H "Authorization: Bearer $TOKEN" -L "$apk_url" -o "$apk_file"
else
  curl -fsSL -L "$apk_url" -o "$apk_file"
fi

cd "$ROOT/docker"
if ! docker compose -f docker-compose.client.yml ps backend --status running -q 2>/dev/null | grep -q .; then
  echo "Backend belum jalan — lewati publish APK."
  exit 0
fi

docker cp "$apk_file" creativepos-backend:/tmp/creativepos.apk
docker compose -f docker-compose.client.yml exec -T backend \
  php scripts/publish-apk.php "/tmp/creativepos.apk" "$version" "$build" "APK dari GitHub Release $tag_name"

echo "APK dipublish ke server."