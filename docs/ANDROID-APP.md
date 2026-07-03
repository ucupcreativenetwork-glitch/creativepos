# CreativePOS — Aplikasi Android

## Flutter (disarankan)

Aplikasi native **Flutter** di `flutter_app/` — POS, inventori, member, delivery, CRM, offline queue, printer Bluetooth.

```powershell
# Setup & build
powershell -ExecutionPolicy Bypass -File D:\pos\scripts\setup-flutter.ps1
powershell -ExecutionPolicy Bypass -File D:\pos\scripts\build-flutter-android.ps1 -Release
```

Panduan lengkap: `flutter_app/docs/BUILD_ANDROID.md` (signing, Play Store, FCM).

Package: `id.creativenetwork.creativepos_mobile`

---

## Capacitor (legacy)

Aplikasi alternatif dengan **Capacitor** — membungkus web app CreativePOS yang sudah ada.

## Fitur

- Login & POS di tablet/HP Android
- Koneksi ke server client via IP LAN (`http://192.168.x.x`)
- Mode offline POS (PWA + IndexedDB, sama seperti browser)
- Install dari APK (sideload) atau Play Store internal

## Persyaratan Build

| Software | Versi |
|----------|-------|
| Node.js | 20+ |
| Android Studio | 2024+ |
| JDK | 17 |
| Android SDK | API 34 |

## Build APK

### 1. Install dependensi

```bash
cd mobile
npm install
```

### 2. Sync Capacitor + buka Android Studio

```bash
npm run cap:sync
npm run android:open
```

### 3. Build release APK

Di Android Studio: **Build → Build Bundle(s) / APK(s) → Build APK(s)**

Atau via CLI:

```bash
npm run android:build
```

APK ada di: `mobile/android/app/build/outputs/apk/release/`

### Windows (PowerShell)

```powershell
cd D:\pos\mobile
npm install
npm run cap:sync
npm run android:open
```

## Cara Pakai di Tablet Client

1. Pasang APK di tablet kasir
2. Buka app → layar **Atur Server**
3. Masukkan URL server, contoh: `http://192.168.1.50`
4. App mengecek `/api/v1/health` lalu membuka `/pos`
5. Login dengan akun kasir

URL server tersimpan — buka berikutnya langsung ke POS.

## Konfigurasi Server untuk Android

Server client harus sudah terinstall (`scripts/install-client.ps1`).

Pastikan tablet dan server **satu jaringan WiFi/LAN**.

HTTP (bukan HTTPS) di LAN didukung — `usesCleartextTraffic` sudah diaktifkan.

## Struktur Folder

```
mobile/
├── www/              # Bootstrap (pilih server URL)
├── android/          # Project Android Studio
├── capacitor.config.ts
└── package.json
```

## Update App

Setelah update frontend di server, **tidak perlu** rebuild APK — app memuat UI dari server.

Rebuild APK hanya jika ada perubahan:
- Bootstrap / splash screen
- Permission Android
- Plugin Capacitor native