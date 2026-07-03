# CreativePOS — Instalasi Server Client (On-Premise)

Panduan memasang CreativePOS di server milik client (toko, restoran, kantor) — tanpa cloud SaaS.

## Persyaratan Server

| Item | Minimum |
|------|---------|
| OS | Ubuntu 22.04+ atau Windows Server + Docker Desktop |
| CPU | 2 core |
| RAM | 4 GB |
| Disk | 20 GB |
| Jaringan | LAN / WiFi toko (tablet & kasir akses IP server) |

Software: **Docker** + **Docker Compose**

## Instalasi Cepat

### Windows (PowerShell)

```powershell
cd D:\pos
powershell -ExecutionPolicy Bypass -File scripts\install-client.ps1
```

Opsional — tentukan IP manual:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-client.ps1 -AppHost 192.168.1.50
```

### Linux (Ubuntu)

```bash
cd /opt/creativepos
chmod +x scripts/install-client.sh
sudo bash scripts/install-client.sh 192.168.1.50
```

## Setelah Instalasi

| Akses | URL |
|-------|-----|
| Dashboard | `http://IP-SERVER/` |
| POS | `http://IP-SERVER/pos` |
| Daftar akun | `http://IP-SERVER/register` |

1. Buka dari PC kasir: `http://IP-SERVER/register`
2. Buat akun bisnis pertama (owner)
3. Atur outlet, produk, metode bayar di **Pengaturan**
4. Tablet/Android: pasang APK atau buka browser → arahkan ke IP server

## Arsitektur Client

```
[Tablet Android / PC Kasir]
        │
        ▼ HTTP (port 80)
   ┌─────────┐
   │  Nginx  │  ← satu pintu masuk
   └────┬────┘
        ├── /        → Next.js (frontend)
        ├── /api/v1  → Laravel (backend)
        ├── /storage → file upload
        └── /ws      → WebSocket (KDS)
```

Semua layanan berjalan di Docker (`docker-compose.client.yml`).

## Perintah Operasional

```bash
cd docker

# Status
docker compose -f docker-compose.client.yml ps

# Log backend
docker compose -f docker-compose.client.yml logs -f backend

# Restart
docker compose -f docker-compose.client.yml restart

# Update (setelah dapat versi baru)
docker compose -f docker-compose.client.yml up -d --build
docker compose -f docker-compose.client.yml exec backend php artisan migrate --force
```

## Android

Lihat [ANDROID-APP.md](./ANDROID-APP.md) untuk build APK.

Ringkasnya (Flutter — disarankan):
1. Build APK: `scripts\build-flutter-android.ps1`
2. Pasang di tablet kasir (`flutter_app\dist\*.apk`)
3. Saat pertama buka, masukkan `http://IP-SERVER`
4. Login → POS native

Alternatif Capacitor: build dari folder `mobile/` (lihat ANDROID-APP.md).

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Tidak bisa akses dari tablet | Pastikan tablet & server satu WiFi; cek firewall port 80 |
| Gambar produk tidak muncul | `docker compose exec backend php artisan storage:link` |
| Email tidak terkirim | Pengaturan → Integrasi → Gateway Email (SMTP) |
| WhatsApp gagal | Pengaturan → Integrasi → WhatsApp (Fonnte token) |

## Versi Cloud vs Client

| | Cloud SaaS | Client Server |
|--|------------|---------------|
| Hosting | Creative Network | Server client |
| Domain | creativepos.app | IP LAN / hostname lokal |
| Billing SaaS | Midtrans/Xendit | Opsional / dinonaktifkan |
| Data | Shared cloud | 100% di server client |