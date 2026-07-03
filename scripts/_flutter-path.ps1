# Resolves Flutter SDK — adds known install paths to the current session PATH.
function Initialize-FlutterBuildEnv {
    # Pindahkan cache Gradle ke drive D agar tidak memenuhi C:
    $gradleHome = "D:\pos\.gradle-home"
    if (-not (Test-Path $gradleHome)) {
        New-Item -ItemType Directory -Force -Path $gradleHome | Out-Null
    }
    $env:GRADLE_USER_HOME = $gradleHome

    # Pub cache di D: — hindari error Kotlin "different roots" (C: vs D:)
    $pubCache = "D:\pos\.pub-cache"
    if (-not (Test-Path $pubCache)) {
        New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
    }
    $env:PUB_CACHE = $pubCache
}

function Resolve-FlutterPath {
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        return $true
    }

    $candidates = @(
        "C:\src\flutter\bin",
        "$env:LOCALAPPDATA\flutter\bin",
        "$env:USERPROFILE\flutter\bin",
        "$env:USERPROFILE\scoop\apps\flutter\current\bin"
    )

    $downloads = Join-Path $env:USERPROFILE "Downloads"
    if (Test-Path $downloads) {
        Get-ChildItem -Path $downloads -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like "flutter*" } |
            ForEach-Object {
                $bin = Join-Path $_.FullName "bin"
                if (Test-Path (Join-Path $bin "flutter.bat")) {
                    $candidates += $bin
                }
            }
    }

    foreach ($bin in $candidates) {
        if (Test-Path (Join-Path $bin "flutter.bat")) {
            $env:Path = "$bin;$env:Path"
            Write-Host "Flutter ditemukan: $bin" -ForegroundColor Green
            return $true
        }
    }

    return $false
}

function Ensure-FlutterAvailable {
    Initialize-FlutterBuildEnv
    if (Resolve-FlutterPath) { return }

    Write-Host "Flutter SDK tidak ditemukan." -ForegroundColor Red
    Write-Host ""
    Write-Host "Install: https://docs.flutter.dev/get-started/install/windows"
    Write-Host "Ekstrak ke C:\src\flutter lalu jalankan:"
    Write-Host '  [Environment]::SetEnvironmentVariable("Path", "C:\src\flutter\bin;" + [Environment]::GetEnvironmentVariable("Path","User"), "User")'
    Write-Host ""
    Write-Host "Atau jalankan: powershell -File D:\pos\scripts\setup-flutter.ps1"
    exit 1
}