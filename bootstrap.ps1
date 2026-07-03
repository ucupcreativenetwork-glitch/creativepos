# CreativePOS — Bootstrap server kosong (Windows) dari GitHub
# Usage (Administrator):
#   powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.ps1 | iex"
#   # IP opsional (tanpa -AppHost = auto-detect):
#   powershell -ExecutionPolicy Bypass -File bootstrap.ps1
#   powershell -ExecutionPolicy Bypass -File bootstrap.ps1 -AppHost 10.110.1.15

param(
    [string]$AppHost = "",
    [int]$AppPort = 80,
    [string]$InstallDir = "D:\creativepos",
    [string]$GitHubRepo = "ucupcreativenetwork-glitch/creativepos",
    [string]$GitHubBranch = "main"
)

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$Raw = "https://raw.githubusercontent.com/$GitHubRepo/$GitHubBranch"
$Tmp = Join-Path $env:TEMP "creativepos-bootstrap"

Write-Host "`n╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  CreativePOS Bootstrap (Windows)         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝`n"

New-Item -ItemType Directory -Path $Tmp -Force | Out-Null

Write-Host "[1/4] Mengunduh skrip prerequisites..."
$prereq = Join-Path $Tmp "install-prerequisites.ps1"
Invoke-WebRequest -Uri "$Raw/scripts/install-prerequisites.ps1" -OutFile $prereq -UseBasicParsing
& $prereq

Write-Host "[2/4] Clone repository..."
if (Test-Path (Join-Path $InstallDir ".git")) {
    Push-Location $InstallDir
    git pull --ff-only origin $GitHubBranch
    Pop-Location
} else {
    $url = "https://github.com/$GitHubRepo.git"
    if ($env:GITHUB_TOKEN) {
        $url = "https://$($env:GITHUB_TOKEN)@github.com/$GitHubRepo.git"
    }
    git clone --depth 1 --branch $GitHubBranch $url $InstallDir
}

Write-Host "[3/4] Install CreativePOS..."
$env:SKIP_PREREQUISITES = "1"
$params = @{ SkipPrerequisites = $true }
if ($AppHost) { $params.AppHost = $AppHost }
if ($AppPort) { $params.AppPort = $AppPort }

Push-Location $InstallDir
& (Join-Path $InstallDir "install.ps1") @params
Pop-Location

Write-Host "[4/4] Selesai." -ForegroundColor Green