# Jalankan app tanpa perlu Flutter di PATH (auto-detect C:\src\flutter)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
. (Join-Path $Root "scripts\_flutter-path.ps1")
Ensure-FlutterAvailable
Initialize-FlutterBuildEnv
Set-Location $PSScriptRoot
flutter run @args