# Setup Flutter platform folders for creativepos_mobile

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$App = Join-Path $Root "flutter_app"

. (Join-Path $Root "scripts\_flutter-path.ps1")
Ensure-FlutterAvailable

# Persist PATH if using C:\src\flutter and not yet in user PATH
$flutterBin = "C:\src\flutter\bin"
if ((Test-Path "$flutterBin\flutter.bat")) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$flutterBin*") {
        [Environment]::SetEnvironmentVariable("Path", "$flutterBin;$userPath", "User")
        Write-Host "PATH permanen diperbarui: $flutterBin" -ForegroundColor Green
        Write-Host "Buka terminal baru agar 'flutter' dikenali di semua sesi." -ForegroundColor Yellow
    }
}

Push-Location $App

Write-Host "Flutter: $(flutter --version | Select-Object -First 1)" -ForegroundColor Cyan

if (-not (Test-Path "android\gradlew.bat")) {
    Write-Host "Menjalankan flutter create untuk melengkapi android/..." -ForegroundColor Yellow
    flutter create . --org id.creativenetwork --project-name creativepos_mobile --platforms android
}

flutter pub get

$Gradle = Join-Path $App "android\app\build.gradle.kts"
if (Test-Path $Gradle) {
    $content = Get-Content $Gradle -Raw
    if ($content -notmatch "minSdk\s*=\s*26") {
        $content = $content -replace "minSdk\s*=\s*flutter\.minSdkVersion", "minSdk = 26"
        Set-Content $Gradle $content -NoNewline
        Write-Host "minSdk diset ke 26" -ForegroundColor Green
    }
}

$KeyExample = Join-Path $App "android\key.properties.example"
$KeyProps = Join-Path $App "android\key.properties"
if ((Test-Path $KeyExample) -and -not (Test-Path $KeyProps)) {
    Write-Host "Buat android/key.properties dari key.properties.example untuk release signing" -ForegroundColor Yellow
}

$GsExample = Join-Path $App "android\app\google-services.json.example"
$Gs = Join-Path $App "android\app\google-services.json"
if ((Test-Path $GsExample) -and -not (Test-Path $Gs)) {
    Write-Host "FCM opsional: salin google-services.json.example -> google-services.json" -ForegroundColor Yellow
}

flutter doctor -v

Pop-Location

Write-Host "`nSetup selesai." -ForegroundColor Green
Write-Host "  cd D:\pos\flutter_app"
Write-Host "  flutter run"
Write-Host "  powershell -File D:\pos\scripts\build-flutter-android.ps1"