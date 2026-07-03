# CreativePOS — instalasi server dari GitHub (Windows)
# Usage:
#   git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git D:\creativepos
#   cd D:\creativepos
#   powershell -ExecutionPolicy Bypass -File install.ps1 -AppHost 192.168.1.50

param(
    [string]$AppHost = "",
    [int]$AppPort = 80,
    [switch]$SkipSeed,
    [switch]$SkipApk
)

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = Join-Path $Root "scripts\install-from-github.ps1"

$params = @{}
if ($AppHost) { $params.AppHost = $AppHost }
if ($AppPort) { $params.AppPort = $AppPort }
if ($SkipSeed) { $params.SkipSeed = $true }
if ($SkipApk) { $params.SkipApk = $true }

& $script @params