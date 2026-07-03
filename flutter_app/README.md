# CreativePOS Mobile (Flutter)

Aplikasi Android native untuk CreativePOS — menggunakan REST API Laravel yang sudah ada.

## Persyaratan

- Flutter 3.24+ (stable)
- Android SDK API 26+
- JDK 17
- Server CreativePOS berjalan (`scripts/install-client.ps1`)

## Setup

```powershell
# 1. Install Flutter SDK: https://docs.flutter.dev/get-started/install/windows
# 2. Generate platform folders (android) jika belum ada:
powershell -ExecutionPolicy Bypass -File ..\scripts\setup-flutter.ps1

cd D:\pos\flutter_app
flutter pub get
flutter run
```

## Build APK / AAB

```powershell
# Setup Android (sekali)
powershell -ExecutionPolicy Bypass -File ..\scripts\setup-flutter.ps1

# Debug APK
powershell -ExecutionPolicy Bypass -File ..\scripts\build-flutter-android.ps1

# Release APK
powershell -ExecutionPolicy Bypass -File ..\scripts\build-flutter-android.ps1 -Release

# Play Store AAB
powershell -ExecutionPolicy Bypass -File ..\scripts\build-flutter-android.ps1 -Bundle
```

Output: `flutter_app/dist/`  
Panduan lengkap: `docs/BUILD_ANDROID.md` (signing, FCM, Play Console).

## Dokumentasi

| File | Isi |
|------|-----|
| `docs/API_ENDPOINTS.md` | Peta endpoint backend |
| `docs/MISSING_ENDPOINTS.md` | API yang perlu ditambah di Laravel |
| `docs/ARCHITECTURE.md` | Struktur & pola kode |

## Konfigurasi Server

Saat pertama buka app, masukkan URL server client:
`http://192.168.1.50` (IP LAN server toko)

## Test

```bash
flutter test
```