# Build CreativePOS Android APK (requires Android Studio + SDK)
# Usage: powershell -ExecutionPolicy Bypass -File scripts\build-android.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Mobile = Join-Path $Root "mobile"

Write-Host "=== CreativePOS Android Build ===" -ForegroundColor Cyan

Push-Location $Mobile

if (-not (Test-Path "node_modules")) {
    npm install
}

if (-not (Test-Path "android")) {
    npx cap add android
}

npm run cap:sync

if (Test-Path "android\gradlew.bat") {
    Push-Location android
    .\gradlew.bat assembleRelease
    Pop-Location
    Write-Host "`nAPK: mobile\android\app\build\outputs\apk\release\" -ForegroundColor Green
} else {
    Write-Host "Buka Android Studio untuk build APK:" -ForegroundColor Yellow
    npx cap open android
}

Pop-Location