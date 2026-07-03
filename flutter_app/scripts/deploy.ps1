# Build + publish ke server + install ke HP (semua otomatis)
# Usage: .\scripts\deploy.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Backend = "D:\pos\backend"

Write-Host "=== CreativePOS Deploy ===" -ForegroundColor Cyan

# 1. Build APK
& "$Root\scripts\build-apk.ps1"
if ($LASTEXITCODE -ne 0) { exit 1 }

# 2. Publish ke server (OTA auto-update)
$apk = Get-ChildItem "$Root\dist" -Filter "*-release.apk" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if ($apk) {
    $pubspec = Get-Content "$Root\pubspec.yaml" -Raw
    if ($pubspec -match 'version:\s*([\d.]+)\+(\d+)') {
        $ver = $Matches[1]
        $build = $Matches[2]
        Write-Host "Publishing ke server OTA..." -ForegroundColor Yellow
        Push-Location $Backend
        php scripts/publish-apk.php $apk.FullName $ver $build "Deploy otomatis"
        Pop-Location
    }
}

# 3. Install ke HP jika terhubung USB
Write-Host "Mencoba install ke HP..." -ForegroundColor Yellow
& "$Root\scripts\install-to-phone.ps1" -Apk $apk.FullName

Write-Host "Deploy selesai." -ForegroundColor Green