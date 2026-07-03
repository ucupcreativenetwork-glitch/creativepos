# Deploy CreativePOS monorepo to GitHub
param(
    [string]$Remote = "origin",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path $PSScriptRoot -Parent

Set-Location $Root

if (-not (Test-Path ".git")) {
    git init -b $Branch
    git config user.name "ucupcreativenetwork"
    git config user.email "ucupcreativenetwork-glitch@users.noreply.github.com"
}

$status = git status --porcelain
if ($status) {
    git add -A
    git commit -m "chore: deploy CreativePOS v1.4.0 — backend, frontend, flutter, remote agent"
}

$remotes = git remote 2>$null
if ($remotes -notcontains $Remote) {
    Write-Host "Remote '$Remote' belum ada. Tambahkan dulu:"
    Write-Host "  git remote add origin https://github.com/ucupcreativenetwork-glitch/creativepos.git"
    exit 1
}

git push -u $Remote $Branch
Write-Host "Deploy ke GitHub selesai."