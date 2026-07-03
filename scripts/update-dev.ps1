# Update CreativePOS di komputer development (tanpa Docker)
# Usage: powershell -ExecutionPolicy Bypass -File scripts\update-dev.ps1
param(
    [switch]$SkipFlutter,
    [switch]$SkipFrontendBuild,
    [switch]$SkipComposer
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$php = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\PHP.PHP.8.4_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe"
if (-not (Test-Path $php)) {
    $phpCmd = Get-Command php -ErrorAction SilentlyContinue
    if ($phpCmd) { $php = $phpCmd.Source }
}
if (-not $php) { throw "PHP tidak ditemukan. Install PHP 8.4 atau set PATH." }

Write-Host "=== CreativePOS - Update Development ===" -ForegroundColor Cyan
Push-Location $Root

if (-not (Test-Path ".git")) {
    throw "Bukan folder git. Clone dari GitHub dulu."
}

Write-Host "`n[1/5] Git pull dari GitHub..." -ForegroundColor Yellow
$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
git fetch origin main 2>&1 | Out-Host
git pull --ff-only origin main 2>&1 | Out-Host
$ErrorActionPreference = $prevEap
if ($LASTEXITCODE -ne 0) { throw "git pull gagal (exit $LASTEXITCODE)" }

if (-not $SkipComposer) {
    Write-Host "`n[2/5] Composer install..." -ForegroundColor Yellow
    Push-Location (Join-Path $Root "backend")
    $composerPhar = Join-Path $Root "backend\composer.phar"
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    if (Test-Path "composer.phar") {
        & $php composer.phar install --no-interaction --prefer-dist --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-posix
    } elseif (Test-Path $composerPhar) {
        & $php $composerPhar install --no-interaction --prefer-dist --ignore-platform-req=ext-pcntl --ignore-platform-req=ext-posix
    } else {
        throw "composer.phar tidak ditemukan di backend/"
    }
    $ErrorActionPreference = $prevEap
    if ($LASTEXITCODE -ne 0) { throw "Composer install gagal (exit $LASTEXITCODE)" }
    Pop-Location
} else {
    Write-Host "`n[2/5] Lewati composer." -ForegroundColor DarkGray
}

Write-Host "`n[3/5] Database migrate..." -ForegroundColor Yellow
Push-Location (Join-Path $Root "backend")
& $php artisan migrate --force
Pop-Location

Write-Host "`n[4/5] Frontend npm install + build..." -ForegroundColor Yellow
Push-Location (Join-Path $Root "frontend")
$prevEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
npm install --no-fund --no-audit
if ($LASTEXITCODE -ne 0) { throw "npm install gagal (exit $LASTEXITCODE)" }
if (-not $SkipFrontendBuild) {
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "npm run build gagal (exit $LASTEXITCODE)" }
}
$ErrorActionPreference = $prevEap
Pop-Location

if (-not $SkipFlutter) {
    Write-Host "`n[5/5] Flutter pub get..." -ForegroundColor Yellow
    $flutter = "C:\src\flutter\bin\flutter.bat"
    if (Test-Path $flutter) {
        Push-Location (Join-Path $Root "flutter_app")
        & $flutter pub get
        Pop-Location
    } else {
        Write-Host "Flutter tidak ditemukan di C:\src\flutter - lewati." -ForegroundColor DarkYellow
    }
} else {
    Write-Host "`n[5/5] Lewati Flutter." -ForegroundColor DarkGray
}

Pop-Location
Write-Host "`nUpdate development selesai." -ForegroundColor Green
Write-Host "Jalankan ulang: backend (php artisan serve), frontend (npm run dev), MySQL (XAMPP)" -ForegroundColor Cyan