# Install APK langsung ke HP via USB (tanpa login web)
# Persiapan HP:
#   1. Aktifkan Developer Options + USB Debugging
#   2. Colokkan kabel USB, pilih "File transfer"
#   3. Izinkan debugging saat diminta di HP

param(
    [string]$Apk = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent
$Adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

if (-not (Test-Path $Adb)) {
    Write-Host "ADB tidak ditemukan. Install Android SDK Platform-Tools." -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrEmpty($Apk)) {
    $dist = Join-Path $Root "dist"
    $Apk = Get-ChildItem $dist -Filter "*.apk" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}

if (-not $Apk -or -not (Test-Path $Apk)) {
    Write-Host "APK tidak ditemukan. Jalankan dulu: .\scripts\build-apk.ps1" -ForegroundColor Red
    exit 1
}

Write-Host "Menunggu HP terhubung (USB debugging)..." -ForegroundColor Yellow
& $Adb wait-for-device

$devices = & $Adb devices | Select-String "device$"
if (-not $devices) {
    Write-Host "HP belum terdeteksi. Cek USB debugging & kabel." -ForegroundColor Red
    exit 1
}

Write-Host "Menginstall: $Apk" -ForegroundColor Cyan
& $Adb install -r $Apk

if ($LASTEXITCODE -eq 0) {
    Write-Host "BERHASIL — CreativePOS terinstall di HP!" -ForegroundColor Green
} else {
    Write-Host "Gagal install. Coba cabut-pasang USB atau uninstall versi lama dulu." -ForegroundColor Red
    exit 1
}