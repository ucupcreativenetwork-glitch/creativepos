# Clone (opsional) + instalasi penuh CreativePOS dari GitHub (Windows)
param(
    [string]$InstallDir = "",
    [string]$AppHost = "",
    [int]$AppPort = 80,
    [switch]$Clone,
    [switch]$SkipSeed,
    [switch]$SkipApk,
    [string]$GitHubToken = $env:GITHUB_TOKEN,
    [string]$GitHubRepo = "https://github.com/ucupcreativenetwork-glitch/creativepos.git"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Clone-Repo {
    param([string]$Target)
    if (Test-Path (Join-Path $Target ".git")) {
        Write-Host "Repo sudah ada — pull terbaru..."
        Push-Location $Target
        git pull --ff-only origin main
        Pop-Location
        return
    }

    $parent = Split-Path $Target -Parent
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $url = $GitHubRepo
    if ($GitHubToken) {
        $url = $GitHubRepo -replace '^https://', "https://${GitHubToken}@"
    }

    Write-Host "Meng-clone $GitHubRepo → $Target"
    git clone --depth 1 --branch main $url $Target
}

if ($Clone) {
    if ([string]::IsNullOrWhiteSpace($InstallDir)) {
        throw "Gunakan -Clone -InstallDir D:\creativepos"
    }
    Clone-Repo $InstallDir
    $Root = $InstallDir
}

if (-not (Test-Path (Join-Path $Root "scripts\install-client.ps1"))) {
    throw "Bukan folder CreativePOS. Clone dulu atau jalankan dari root repo."
}

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   CreativePOS — Install dari GitHub      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝`n"

$clientParams = @{}
if ($AppHost) { $clientParams.AppHost = $AppHost }
if ($AppPort) { $clientParams.AppPort = $AppPort }
if ($SkipSeed) { $clientParams.SkipSeed = $true }

Push-Location $Root
& (Join-Path $Root "scripts\install-client.ps1") @clientParams

if (-not $SkipApk) {
    try {
        & (Join-Path $Root "scripts\install-mobile-apk.ps1")
    } catch {
        Write-Host "(APK release belum tersedia — lewati)" -ForegroundColor Yellow
    }
}

& (Join-Path $Root "scripts\post-install.ps1")
Pop-Location