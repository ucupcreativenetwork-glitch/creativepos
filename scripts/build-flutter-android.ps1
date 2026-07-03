# Build CreativePOS Flutter Android APK / AAB
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\build-flutter-android.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\build-flutter-android.ps1 -Release
#   powershell -ExecutionPolicy Bypass -File scripts\build-flutter-android.ps1 -Bundle

param(
    [switch]$Debug,
    [switch]$Release,
    [switch]$Bundle,
    [switch]$Setup
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$App = Join-Path $Root "flutter_app"
$OutDir = Join-Path $App "dist"

. (Join-Path $Root "scripts\_flutter-path.ps1")

function Run-Setup {
    $setup = Join-Path $Root "scripts\setup-flutter.ps1"
    & $setup
}

Ensure-FlutterAvailable

if ($Setup -or -not (Test-Path (Join-Path $App "android\gradlew.bat"))) {
    Run-Setup
}

Push-Location $App

Write-Host "=== CreativePOS Flutter Android Build ===" -ForegroundColor Cyan
flutter pub get
flutter test
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    exit $LASTEXITCODE
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

if ($Bundle) {
    Write-Host "Building App Bundle (AAB)..." -ForegroundColor Yellow
    flutter build appbundle --release
    $src = Join-Path $App "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $OutDir "creativepos-release.aab") -Force
        Write-Host "AAB: $OutDir\creativepos-release.aab" -ForegroundColor Green
    }
}
elseif ($Release) {
    Write-Host "Building Release APK..." -ForegroundColor Yellow
    flutter build apk --release --split-per-abi
    $apkDir = Join-Path $App "build\app\outputs\flutter-apk"
    Get-ChildItem $apkDir -Filter "*.apk" | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $OutDir $_.Name) -Force
        Write-Host "APK: $OutDir\$($_.Name)" -ForegroundColor Green
    }
}
else {
    Write-Host "Building Debug APK..." -ForegroundColor Yellow
    flutter build apk --debug
    $src = Join-Path $App "build\app\outputs\flutter-apk\app-debug.apk"
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $OutDir "creativepos-debug.apk") -Force
        Write-Host "APK: $OutDir\creativepos-debug.apk" -ForegroundColor Green
    }
}

Pop-Location

Write-Host "`nSelesai. Install debug ke device:" -ForegroundColor Green
Write-Host "  adb install -r flutter_app\dist\creativepos-debug.apk"