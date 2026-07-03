# Update CreativePOS dari GitHub + rebuild Docker (Windows)
param([switch]$SkipApk)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

if (-not (Test-Path (Join-Path $Root ".git"))) {
    throw "Folder ini bukan git repo. Clone dari GitHub dulu."
}

Write-Host "=== CreativePOS Update dari GitHub ===" -ForegroundColor Cyan
Push-Location $Root

git fetch origin main
git pull --ff-only origin main

Push-Location (Join-Path $Root "docker")
Write-Host "Membangun ulang container..."
docker compose -f docker-compose.client.yml up -d --build

Write-Host "Menunggu MySQL..."
for ($i = 1; $i -le 30; $i++) {
    $ok = docker compose -f docker-compose.client.yml exec -T mysql mysqladmin ping -h localhost 2>$null
    if ($LASTEXITCODE -eq 0) { break }
    Start-Sleep -Seconds 2
}

docker compose -f docker-compose.client.yml exec -T backend php artisan migrate --force
docker compose -f docker-compose.client.yml exec -T backend php artisan config:cache
docker compose -f docker-compose.client.yml exec -T backend php artisan route:cache

Pop-Location

if (-not $SkipApk) {
    try { & (Join-Path $Root "scripts\install-mobile-apk.ps1") } catch {}
}

& (Join-Path $Root "scripts\post-install.ps1")
Pop-Location

Write-Host "Update selesai." -ForegroundColor Green