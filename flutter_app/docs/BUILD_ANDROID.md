# Build Android — CreativePOS Mobile

Panduan lengkap build APK/AAB dan publikasi Play Store untuk aplikasi Flutter `creativepos_mobile`.

## Prasyarat

| Tool | Versi |
|------|-------|
| Flutter SDK | 3.24+ stable |
| Android SDK | API 34 (compile), min SDK 26 |
| JDK | 17 |
| Android Studio | Terbaru (untuk SDK Manager) |

```powershell
# Setup sekali (Windows)
powershell -ExecutionPolicy Bypass -File D:\pos\scripts\setup-flutter.ps1
```

## Build Cepat

```powershell
# Debug APK (testing internal / sideload)
powershell -ExecutionPolicy Bypass -File D:\pos\scripts\build-flutter-android.ps1

# Release APK (multi-ABI: arm64, armeabi-v7a, x86_64)
powershell -ExecutionPolicy Bypass -File D:\pos\scripts\build-flutter-android.ps1 -Release

# App Bundle untuk Google Play
powershell -ExecutionPolicy Bypass -File D:\pos\scripts\build-flutter-android.ps1 -Bundle
```

Output disalin ke `flutter_app/dist/`.

### Manual (tanpa script)

```bash
cd flutter_app
flutter pub get
flutter test
flutter build apk --debug
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

| Build | Output |
|-------|--------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | `build/app/outputs/flutter-apk/app-*-release.apk` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |

## Signing Release

### 1. Buat keystore (sekali)

```bash
keytool -genkey -v -keystore creativepos-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias creativepos
```

Simpan `creativepos-release.jks` di `flutter_app/android/` (sudah di `.gitignore`).

### 2. Konfigurasi signing

```bash
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=PASSWORD_KEYSTORE
keyPassword=PASSWORD_KEY
keyAlias=creativepos
storeFile=../creativepos-release.jks
```

`android/app/build.gradle.kts` sudah membaca `key.properties` otomatis.

## Firebase / FCM (Opsional)

Push notification membutuhkan Firebase project client:

1. Buat project di [Firebase Console](https://console.firebase.google.com)
2. Tambah app Android — package: `id.creativenetwork.creativepos_mobile`
3. Download `google-services.json` → `android/app/google-services.json`
4. Plugin Google Services aktif otomatis jika file ada

Tanpa `google-services.json`, app tetap build; FCM di-skip gracefully.

## Konfigurasi Android

| Setting | Nilai |
|---------|-------|
| Application ID | `id.creativenetwork.creativepos_mobile` |
| minSdk | 26 (Android 8.0) |
| targetSdk | Flutter default (34+) |
| Cleartext HTTP | Aktif (server LAN client) |
| Namespace | `id.creativenetwork.creativepos_mobile` |

### Permission

| Permission | Digunakan untuk |
|------------|-----------------|
| `INTERNET` | API REST ke server client |
| `CAMERA` | Scan barcode POS & QR |
| `BLUETOOTH_CONNECT` / `BLUETOOTH_SCAN` | Printer ESC/POS |
| `ACCESS_FINE_LOCATION` | GPS delivery driver |
| `USE_BIOMETRIC` | Login biometric (opsional) |
| `VIBRATE` / `WAKE_LOCK` | FCM notifikasi |

## Install ke Device

```bash
# USB debugging aktif
adb devices
adb install -r flutter_app/dist/creativepos-debug.apk

# Atau langsung dari Flutter
cd flutter_app
flutter run --release
```

## Google Play Console

### 1. Buat aplikasi

1. [Google Play Console](https://play.google.com/console) → Create app
2. Nama: **CreativePOS**
3. Default language: Indonesian
4. App / Game: App
5. Free / Paid: sesuai model bisnis client

### 2. Upload ke Internal testing

1. **Testing → Internal testing** → Create release
2. Upload `creativepos-release.aab`
3. Tambah tester (email Google)
4. Review dan rollout

### 3. Store listing (draft)

**Judul singkat:** CreativePOS  
**Deskripsi singkat:** Aplikasi POS Android untuk toko — terhubung ke server CreativePOS Anda.  
**Deskripsi lengkap:**

```
CreativePOS Mobile adalah aplikasi kasir Android untuk bisnis retail dan F&B.
Terhubung langsung ke server CreativePOS di toko Anda (on-premise / LAN).

Fitur:
• POS — katalog, keranjang, checkout, hold bill, scan barcode
• Inventori — produk, stok, alert
• Member & loyalty — daftar, poin, wallet
• QR Menu — pesanan tamu via QR meja
• Reservasi — booking & check-in
• Delivery — tracking order & GPS driver
• CRM — tiket support & FAQ
• Notifikasi push (FCM)
• Offline queue — transaksi tetap jalan tanpa internet
• Printer Bluetooth ESC/POS 58/80mm

Setup: masukkan URL server toko saat pertama buka (contoh http://192.168.1.50).
Data disimpan di server client Anda, bukan cloud pihak ketiga.
```

**Kategori:** Business  
**Email support:** support@client-domain.com  
**Privacy policy URL:** wajib (halaman privacy di domain client)

### 4. Data Safety

Jawab sesuai perilaku app:

| Data | Dikumpulkan | Dikirim | Tujuan |
|------|-------------|---------|--------|
| Email, nama | Ya | Ke server client | Akun & login |
| Lokasi GPS | Ya (opsional) | Ke server client | Delivery tracking |
| Info pembayaran | Tidak langsung | — | Pembayaran di POS server |
| Device ID / FCM token | Ya | Ke server client | Push notification |

- Data **tidak** dijual ke pihak ketiga
- Data dikirim ke **server yang dikonfigurasi user** (bukan server Creative Network global)
- Enkripsi in transit: HTTPS direkomendasikan; HTTP LAN didukung untuk instalasi client

### 5. Content rating

Isi kuesioner IARC — biasanya **Everyone** / PEGI 3 untuk app bisnis tanpa konten sensitif.

### 6. Target API

Google Play mensyaratkan target API terbaru — pastikan `flutter doctor` dan SDK 34+ terpasang sebelum upload.

### 7. Checklist sebelum production

- [ ] `flutter test` lulus
- [ ] Release signed dengan keystore production
- [ ] Privacy policy URL aktif
- [ ] Screenshot phone + tablet (min 2)
- [ ] Icon 512×512 PNG
- [ ] Feature graphic 1024×500 (opsional)
- [ ] Uji di device fisik: login, POS checkout, offline sync, printer
- [ ] HTTPS reverse proxy untuk production (disarankan)

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| `flutter.sdk not set` | Jalankan `flutter pub get` atau `setup-flutter.ps1` |
| Gradle gagal | `cd android && gradlew clean`, lalu build ulang |
| Bluetooth printer tidak muncul | Pair printer di Settings Android dulu |
| Cleartext HTTP blocked | `usesCleartextTraffic=true` sudah di manifest |
| FCM tidak jalan | Pastikan `google-services.json` ada & valid |

## Arsitektur Deploy Client

```
[Tablet Android] --WiFi/LAN--> [Server Client Docker]
       |                              |
  Flutter App                   Laravel API
  (APK/AAB)                     PostgreSQL
```

App **tidak** membutuhkan internet publik — cukup akses ke server toko.