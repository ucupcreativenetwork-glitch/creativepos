# CreativePOS — Perbarui IP/domain dari file konfigurasi atau auto-detect (tanpa reinstall penuh)
# Usage: powershell -ExecutionPolicy Bypass -File scripts\reconfigure-host.ps1 [-AppHost IP] [-AppPort 80]

param(
    [string]$AppHost = "",
    [int]$AppPort = 80
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptDir

. (Join-Path $ScriptDir "lib\Resolve-AppHost.ps1")
$resolved = Resolve-AppHost -Root $Root -CliHost $AppHost -CliPort $AppPort

$AppHost = $resolved.AppHost
$AppPort = $resolved.Port
$AppScheme = $resolved.Scheme
$AppUrl = $resolved.Url

Write-Host "`n=== Reconfigure Host ===" -ForegroundColor Cyan
Write-Host "Host   : $AppHost (sumber: $($resolved.Source))"
Write-Host "URL    : $AppUrl`n"

$DockerEnv = Join-Path $Root "docker\.env"
if (-not (Test-Path $DockerEnv)) {
    Copy-Item (Join-Path $Root "docker\.env.example") $DockerEnv
}
(Get-Content $DockerEnv) `
    -replace '(?m)^APP_HOST=.*', "APP_HOST=$AppHost" `
    -replace '(?m)^APP_PORT=.*', "APP_PORT=$AppPort" | Set-Content $DockerEnv

$BackendEnv = Join-Path $Root "backend\.env"
if (-not (Test-Path $BackendEnv)) {
    throw "backend/.env tidak ditemukan. Jalankan install dulu."
}

$content = Get-Content $BackendEnv -Raw
$content = $content -replace '(?m)^APP_URL=.*', "APP_URL=$AppUrl"
$content = $content -replace '(?m)^FRONTEND_URL=.*', "FRONTEND_URL=$AppUrl"
$content = $content -replace '(?m)^SANCTUM_STATEFUL_DOMAINS=.*', "SANCTUM_STATEFUL_DOMAINS=$AppHost,localhost,127.0.0.1"
$content = $content -replace '(?m)^REVERB_HOST=.*', "REVERB_HOST=$AppHost"
$content = $content -replace '(?m)^REVERB_PORT=.*', "REVERB_PORT=$AppPort"
$content = $content -replace '(?m)^REVERB_SCHEME=.*', "REVERB_SCHEME=$AppScheme"
Set-Content $BackendEnv $content.TrimEnd()

Push-Location (Join-Path $Root "docker")
$running = docker compose -f docker-compose.client.yml ps -q backend 2>$null
if ($running) {
    Write-Host "Menerapkan ke container yang berjalan..." -ForegroundColor Yellow
    docker compose -f docker-compose.client.yml exec -T backend php artisan config:clear
    docker compose -f docker-compose.client.yml exec -T backend php artisan config:cache
    docker compose -f docker-compose.client.yml restart backend frontend nginx 2>$null
    if ($LASTEXITCODE -ne 0) {
        docker compose -f docker-compose.client.yml restart
    }
    Write-Host "Selesai. Akses: $AppUrl" -ForegroundColor Green
} else {
    Write-Host "Container belum berjalan — konfigurasi file sudah diperbarui."
    Write-Host "Jalankan: cd docker; docker compose -f docker-compose.client.yml up -d"
}
Pop-Location