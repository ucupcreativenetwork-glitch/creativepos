# CreativePOS — Instalasi Server Client (On-Premise)

Panduan memasang CreativePOS di server milik client (toko, restoran, kantor) — tanpa cloud SaaS.

## Persyaratan Server

| Item | Minimum |
|------|---------|
| OS | Ubuntu 22.04+ atau Windows 10/11 / Server 2022 |
| CPU | 2 core |
| RAM | 4 GB |
| Disk | 20 GB |
| Jaringan | LAN / WiFi toko (tablet & kasir akses IP server) |

Software diinstall **otomatis** oleh skrip: **Git**, **Docker**, **Docker Compose**

## Server Ubuntu Kosong (1 baris)

Docker, Git, dan CreativePOS terinstall otomatis:

```bash
curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash -s -- 10.110.1.15
```

Ganti `10.110.1.15` dengan IP server Anda.

## Windows Server Kosong (Administrator)

Buka **PowerShell sebagai Administrator**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.ps1 | iex
# Lalu jalankan lagi dengan IP:
powershell -ExecutionPolicy Bypass -File D:\creativepos\bootstrap.ps1 -AppHost 10.110.1.15
```

Atau clone dulu lalu install (Docker Desktop diinstall otomatis):

```powershell
git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git D:\creativepos
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File install.ps1 -AppHost 10.110.1.15
```

## Instalasi dari GitHub (sudah ada Git)

Semua komponen (backend, frontend, database, Redis, nginx) diinstall dari repo GitHub — tidak perlu copy manual.

### Linux — Server baru

```bash
# 1. Clone
sudo git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos

# 2. Install (ganti IP dengan IP server Anda)
cd /opt/creativepos
sudo bash install.sh 10.110.1.15
```

**Repo private?** Buat Personal Access Token (repo scope), lalu:

```bash
export GITHUB_TOKEN=ghp_xxxxxxxx
sudo -E git clone https://${GITHUB_TOKEN}@github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
cd /opt/creativepos && sudo -E bash install.sh 10.110.1.15
```

### Windows — Server baru

```powershell
git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git D:\creativepos
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File install.ps1 -AppHost 10.110.1.15
```

### Update versi terbaru

```bash
cd /opt/creativepos
sudo bash update.sh
```

```powershell
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File update.ps1
```

### APK Android otomatis

Jika ada **GitHub Release** dengan file `.apk` (tag `v1.3.1-18`), skrip install akan:
1. Unduh APK dari Release
2. Publish ke server → `http://IP-SERVER/api/v1/mobile/download/...`

Buat release dari dev machine:

```bash
git tag v1.3.1-18
git push origin v1.3.1-18
# GitHub Actions membangun APK & membuat Release otomatis
```

---

## Instalasi Manual (tanpa GitHub)

### Windows (PowerShell)

```powershell
cd D:\pos
powershell -ExecutionPolicy Bypass -File scripts\install-client.ps1 -AppHost 192.168.1.50
```

### Linux (Ubuntu)

```bash
cd /opt/creativepos
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