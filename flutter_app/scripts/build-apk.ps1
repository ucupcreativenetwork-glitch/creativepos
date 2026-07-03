# CreativePOS — Auto-build release APK
# Usage: .\scripts\build-apk.ps1
#        .\scripts\build-apk.ps1 -Debug

param(
    [switch]$Debug
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Flutter = "C:\src\flutter\bin\flutter.bat"

if (-not (Test-Path $Flutter)) {
    $Flutter = "flutter"
}

Set-Location $Root

# Read version from pubspec.yaml
$pubspec = Get-Content "pubspec.yaml" -Raw
if ($pubspec -match 'version:\s*([\d.]+)\+(\d+)') {
    $version = $Matches[1]
    $build = $Matches[2]
} else {
    $version = "0.0.0"
    $build = "0"
}

Write-Host "=== CreativePOS Auto-Build ===" -ForegroundColor Cyan
Write-Host "Version: $version (build $build)"

$mode = if ($Debug) { "debug" } else { "release" }
$apkName = if ($Debug) { "app-debug.apk" } else { "app-release.apk" }

Write-Host "Building APK ($mode)..." -ForegroundColor Yellow
if ($Debug) {
    & $Flutter build apk --debug
} else {
    & $Flutter build apk --release
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "BUILD FAILED" -ForegroundColor Red
    exit 1
}

$src = Join-Path $Root "build\app\outputs\flutter-apk\$apkName"
$outDir = Join-Path $Root "dist"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$dest = Join-Path $outDir "creativepos-$version-$build-$mode.apk"
Copy-Item $src $dest -Force

Write-Host ""
Write-Host "BUILD SUCCESS" -ForegroundColor Green
Write-Host "APK: $dest"
Write-Host ""
Write-Host "Upload ke Platform Admin:" -ForegroundColor Cyan
Write-Host "  http://10.110.1.15:3000/platform"
Write-Host "  Version: $version | Build: $build"
Write-Host ""