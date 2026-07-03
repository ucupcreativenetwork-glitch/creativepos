# CreativePOS — Auto-install Docker Desktop, Git (Windows)
# Usage (Administrator): powershell -ExecutionPolicy Bypass -File scripts\install-prerequisites.ps1

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "`n=== CreativePOS — Install Prerequisites (Windows) ===" -ForegroundColor Cyan

function Test-Command($name) {
  $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Install-WingetPackage {
    param([string]$Id, [string]$Label)
    if (Test-Command winget) {
        Write-Host "Menginstall $Label via winget..."
        winget install --id $Id -e --accept-package-agreements --accept-source-agreements --silent 2>$null
        return $true
    }
    return $false
}

function Install-ChocoPackage {
    param([string]$Name, [string]$Label)
    if (Test-Command choco) {
        Write-Host "Menginstall $Label via Chocolatey..."
        choco install $Name -y --no-progress
        return $true
    }
    return $false
}

# --- Git ---
if (-not (Test-Command git)) {
    $ok = Install-WingetPackage "Git.Git" "Git"
    if (-not $ok) { $ok = Install-ChocoPackage "git" "Git" }
    if (-not $ok) {
        throw "Git tidak ditemukan. Install manual: https://git-scm.com/download/win"
    }
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                [System.Environment]::GetEnvironmentVariable("Path", "User")
}
Write-Host "Git: $(git --version)" -ForegroundColor Green

# --- WSL2 (dibutuhkan Docker Desktop) ---
if (-not (Test-Command wsl)) {
    Write-Host "Mengaktifkan WSL2..."
    wsl --install --no-distribution 2>$null
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>$null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>$null
    Write-Host "WSL2 diaktifkan — mungkin perlu restart Windows." -ForegroundColor Yellow
}

# --- Docker ---
if (-not (Test-Command docker)) {
    $ok = Install-WingetPackage "Docker.DockerDesktop" "Docker Desktop"
    if (-not $ok) { $ok = Install-ChocoPackage "docker-desktop" "Docker Desktop" }
    if (-not $ok) {
        throw "Docker tidak ditemukan. Install Docker Desktop: https://www.docker.com/products/docker-desktop/"
    }
    Write-Host "Docker Desktop terinstall — tunggu startup..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
}

# Tunggu Docker siap (max 3 menit)
Write-Host "Menunggu Docker siap..."
$ready = $false
for ($i = 1; $i -le 36; $i++) {
    try {
        docker info 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $ready = $true
            break
        }
    } catch {}
    Start-Sleep -Seconds 5
    Write-Host "  ... $($i * 5)s"
}

if (-not $ready) {
    Write-Host ""
    Write-Host "Docker belum siap. Buka Docker Desktop manual, tunggu ikon hijau, lalu jalankan install lagi." -ForegroundColor Yellow
    Write-Host "Atau restart Windows jika baru install WSL2." -ForegroundColor Yellow
    exit 1
}

docker compose version 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker Compose plugin belum aktif — pastikan Docker Desktop versi terbaru." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Docker: $(docker --version)" -ForegroundColor Green
Write-Host "Compose: $(docker compose version)" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Prerequisites siap" -ForegroundColor Green
Write-Host ""