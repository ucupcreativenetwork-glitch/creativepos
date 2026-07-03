# Unduh APK terbaru dari GitHub Releases dan publish ke server lokal
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Repo = if ($env:GITHUB_REPO) { $env:GITHUB_REPO } else { "ucupcreativenetwork-glitch/creativepos" }
$Token = $env:GITHUB_TOKEN

$headers = @{ Accept = "application/vnd.github+json" }
if ($Token) { $headers.Authorization = "Bearer $Token" }

Write-Host "Mencari APK di GitHub Releases ($Repo)..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers $headers
} catch {
    Write-Host "Tidak ada GitHub Release — lewati publish APK."
    return
}

$asset = $release.assets | Where-Object { $_.name -like "*.apk" } | Select-Object -First 1
if (-not $asset) {
    Write-Host "Release ada tapi tanpa file .apk — lewati."
    return
}

$tmp = Join-Path $env:TEMP "creativepos-$(Get-Random).apk"
Write-Host "Mengunduh $($asset.browser_download_url)"
if ($Token) {
    Invoke-WebRequest -Uri $asset.browser_download_url -Headers $headers -OutFile $tmp
} else {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tmp
}

$tag = $release.tag_name -replace '^v', ''
$version = ($tag -split '-')[0]
$build = if ($tag -match '(\d+)$') { $Matches[1] } else { "1" }

Push-Location (Join-Path $Root "docker")
$running = docker compose -f docker-compose.client.yml ps backend --status running -q 2>$null
if (-not $running) {
    Write-Host "Backend belum jalan — lewati publish APK."
    Pop-Location
    return
}

docker cp $tmp creativepos-backend:/tmp/creativepos.apk
docker compose -f docker-compose.client.yml exec -T backend `
  php scripts/publish-apk.php "/tmp/creativepos.apk" $version $build "APK dari GitHub Release $($release.tag_name)"
Pop-Location
Remove-Item $tmp -Force -ErrorAction SilentlyContinue
Write-Host "APK dipublish ke server."