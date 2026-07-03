$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$backendEnv = Join-Path $Root "backend\.env"
$dockerEnv = Join-Path $Root "docker\.env"

$base = $null
if (Test-Path $backendEnv) {
    foreach ($line in Get-Content $backendEnv) {
        if ($line -match '^APP_URL=(.+)$') { $base = $Matches[1].Trim(); break }
    }
}
if (-not $base) {
    $appHost = "localhost"
    $appPort = "80"
    if (Test-Path $dockerEnv) {
        foreach ($line in Get-Content $dockerEnv) {
            if ($line -match '^APP_HOST=(.+)$') { $appHost = $Matches[1].Trim() }
            if ($line -match '^APP_PORT=(.+)$') { $appPort = $Matches[1].Trim() }
        }
    }
    $base = if ($appPort -eq "80") { "http://$appHost" } else { "http://${appHost}:$appPort" }
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              CreativePOS — Siap Digunakan                ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host ("║  Web POS     : {0,-41} ║" -f "$base/pos") -ForegroundColor Green
Write-Host ("║  Dashboard   : {0,-41} ║" -f "$base/") -ForegroundColor Green
Write-Host ("║  Daftar      : {0,-41} ║" -f "$base/register") -ForegroundColor Green
Write-Host ("║  API Health  : {0,-41} ║" -f "$base/api/v1/health") -ForegroundColor Green
Write-Host ("║  APK Mobile  : {0,-41} ║" -f "$base/api/v1/mobile/version?platform=android") -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Akun default (ganti password di production!)            ║" -ForegroundColor Green
Write-Host ("║  Admin       : {0,-41} ║" -f "admin@creativepos.local") -ForegroundColor Green
Write-Host ("║  Password    : {0,-41} ║" -f "Admin123!") -ForegroundColor Green
Write-Host ("║  Super Admin : {0,-41} ║" -f "superadmin@creativepos.local") -ForegroundColor Green
Write-Host ("║  Password    : {0,-41} ║" -f "SuperAdmin123!") -ForegroundColor Green
Write-Host ("║  Platform    : {0,-41} ║" -f "$base/platform") -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Update      : scripts\update-from-github.ps1            ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

try {
    $r = Invoke-WebRequest -Uri "$base/api/v1/health" -UseBasicParsing -TimeoutSec 5
    if ($r.StatusCode -eq 200) { Write-Host "✓ Health check OK" -ForegroundColor Green }
} catch {
    Write-Host "⚠ Health check belum OK — tunggu 1-2 menit." -ForegroundColor Yellow
}