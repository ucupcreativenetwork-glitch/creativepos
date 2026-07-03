# CreativePOS — Tutorial Lengkap

Panduan end-to-end: **pasang server → aktif dipakai → kelola fitur → konfigurasi pembayaran**.

Repo: [github.com/ucupcreativenetwork-glitch/creativepos](https://github.com/ucupcreativenetwork-glitch/creativepos)

---

## Daftar Isi

1. [Ringkasan arsitektur](#1-ringkasan-arsitektur)
2. [Setup server sampai aktif](#2-setup-server-sampai-aktif)
3. [Aktivasi pertama (web & kasir)](#3-aktivasi-pertama-web--kasir)
4. [Aplikasi Android](#4-aplikasi-android)
5. [Ganti / tambah fitur](#5-ganti--tambah-fitur)
6. [Tambah & atur payment gateway](#6-tambah--atur-payment-gateway)
7. [Update & maintenance](#7-update--maintenance)
8. [Troubleshooting](#8-troubleshooting)

---

## 1. Ringkasan arsitektur

```
[Tablet / PC Kasir / Browser]
           │
           ▼ HTTP port 80
      ┌─────────┐
      │  Nginx  │  ← satu pintu masuk
      └────┬────┘
           ├── /           → Next.js (dashboard, POS web)
           ├── /api/v1     → Laravel (backend API)
           ├── /storage    → upload gambar produk
           └── /ws         → WebSocket (KDS)
```

Semua layanan berjalan di Docker (`docker/docker-compose.client.yml`).

| Komponen | Folder | Keterangan |
|----------|--------|------------|
| Backend | `backend/` | Laravel 12, API, billing, integrasi |
| Frontend | `frontend/` | Next.js, dashboard & POS web |
| Mobile | `flutter_app/` | APK Android native |
| Konfigurasi Docker | `docker/.env` | IP server, port, kredensial DB |
| Konfigurasi API | `backend/.env` | APP_URL, payment gateway, Redis |

---

## 2. Setup server sampai aktif

### 2.1 Persyaratan

| Item | Minimum |
|------|---------|
| OS | Ubuntu 22.04+ **atau** Windows 10/11 / Server 2022 |
| CPU | 2 core |
| RAM | 4 GB |
| Disk | 20 GB |
| Jaringan | LAN/WiFi — tablet & kasir harus bisa akses IP server |

Software **Docker**, **Docker Compose**, dan **Git** diinstall otomatis oleh skrip.

### 2.2 Instalasi Ubuntu (server kosong)

**Opsi A — satu baris (disarankan, IP auto-detect):**

```bash
curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash
```

**Opsi B — tentukan IP manual:**

```bash
curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash -s -- 10.110.1.15
```

**Opsi C — clone dulu, lalu install:**

```bash
sudo git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
cd /opt/creativepos
sudo bash install.sh
```

> **Repo private:** set `GITHUB_TOKEN` (PAT scope `repo`) sebelum clone:
> `export GITHUB_TOKEN=ghp_xxxx`

### 2.3 Instalasi Windows

Buka **PowerShell sebagai Administrator**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.ps1 | iex
```

Atau clone manual:

```powershell
git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git D:\creativepos
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File install.ps1
```

### 2.4 Apa yang dilakukan skrip install?

1. Install Docker + Git (jika belum ada)
2. **Auto-detect IP/domain** dari:
   - argumen CLI → `docker/.env` → `backend/.env` → IP LAN → hostname
3. Generate `docker/.env`, `backend/.env`, `frontend/.env.local`
4. Build & jalankan container (MySQL, Redis, backend, frontend, nginx)
5. Migrasi database + seed data demo (bisa dilewati: `SKIP_SEED=1`)
6. Unduh APK dari GitHub Release (jika tersedia)

### 2.5 Verifikasi server aktif

Setelah install selesai, cek:

```bash
# Status container
cd /opt/creativepos/docker
docker compose -f docker-compose.client.yml ps

# Health check API (ganti IP sesuai server Anda)
curl http://10.110.1.15/api/v1/health
```

Respon sukses: `{"status":"ok",...}`

| URL | Fungsi |
|-----|--------|
| `http://IP-SERVER/` | Dashboard |
| `http://IP-SERVER/pos` | POS kasir |
| `http://IP-SERVER/register` | Daftar akun bisnis baru |
| `http://IP-SERVER/api/v1/health` | Cek API |
| `http://IP-SERVER/api/v1/mobile/version?platform=android` | Info APK |

### 2.6 Firewall (Ubuntu)

Pastikan port 80 terbuka di LAN:

```bash
sudo ufw allow 80/tcp
sudo ufw status
```

### 2.7 Ubah IP setelah pindah jaringan

```bash
cd /opt/creativepos
sudo bash scripts/reconfigure-host.sh          # auto-detect ulang
sudo bash scripts/reconfigure-host.sh 192.168.1.50   # manual
```

```powershell
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File scripts\reconfigure-host.ps1
```

---

## 3. Aktivasi pertama (web & kasir)

### 3.1 Buat akun bisnis (Owner)

1. Buka `http://IP-SERVER/register` dari PC kasir
2. Isi nama bisnis, email, password
3. Login → Anda masuk sebagai **Owner**

### 3.2 Wizard onboarding (otomatis muncul)

Ikuti langkah:

| Langkah | Isi |
|---------|-----|
| Profil Bisnis | Nama, logo, alamat, telepon |
| Outlet Pertama | Nama outlet, timezone |
| Produk Pertama | Nama produk, harga, kategori |
| Metode Pembayaran | Centang Cash, Transfer, QRIS, dll. |
| Undang Staff | Email kasir (opsional) |

### 3.3 Pengaturan lanjutan (menu **Pengaturan**)

| Tab | Fungsi |
|-----|--------|
| **Bisnis** | Logo, pajak, service charge, metode bayar POS, toggle fitur |
| **Outlet** | Tambah/edit outlet |
| **Operasional** | Meja & QR menu, slot reservasi |
| **Loyalty** | Poin belanja & redeem |
| **Pengguna** | Tambah kasir, manager, kitchen |
| **Langganan** | Invoice SaaS (jika dipakai) |
| **Integrasi** | Email SMTP, WhatsApp |

### 3.4 Mulai transaksi POS

1. Buka `http://IP-SERVER/pos`
2. Pilih outlet (jika lebih dari satu)
3. Tambah produk ke keranjang → **Bayar** → pilih metode → konfirmasi
4. Struk tercetak / bisa dicetak dari browser

### 3.5 Checklist "server aktif"

- [ ] Health check API OK
- [ ] Bisa login dashboard
- [ ] Minimal 1 outlet & 1 produk
- [ ] Transaksi POS pertama berhasil
- [ ] Tablet/HP di WiFi yang sama bisa buka `http://IP-SERVER/pos`
- [ ] (Opsional) APK terpasang di tablet

---

## 4. Aplikasi Android

### 4.1 Unduh APK dari server

Setelah install, APK tersedia di:

```
http://IP-SERVER/api/v1/mobile/download/{id}
```

Cek versi terbaru:

```
http://IP-SERVER/api/v1/mobile/version?platform=android
```

### 4.2 Pasang di tablet kasir

1. Unduh & install APK (izinkan "Install dari sumber tidak dikenal")
2. Buka app → layar **Atur Server**
3. Masukkan `http://IP-SERVER` (tanpa `/api`)
4. Login dengan akun kasir
5. Mulai jualan di tab **Kasir**

### 4.3 Mode standalone (tanpa server)

APK juga bisa dipakai **offline** — stok & transaksi disimpan lokal di HP. Cocok untuk toko kecil tanpa server. Lihat tab **Toko** di app setelah pilih mode standalone.

Panduan build APK: [ANDROID-APP.md](./ANDROID-APP.md)

---

## 5. Ganti / tambah fitur

Ada **tiga level** pengaturan fitur:

### 5.1 Toggle fitur per bisnis (tanpa coding)

Di **Pengaturan → Bisnis → Fitur Operasional**, owner bisa aktif/nonaktif:

| Fitur | Dampak |
|-------|--------|
| **Reservasi Meja** | Menu `/reservations`, slot waktu di Pengaturan → Operasional |
| **Delivery** | Menu `/delivery` |
| **QR Menu** | Generate QR meja, pelanggan pesan sendiri |

Centang sesuai kebutuhan → **Simpan Profil Bisnis**.

> Fitur hanya muncul jika **paket langganan** bisnis Anda mendukungnya (mis. paket Business+ punya modul reservasi).

### 5.2 Update versi & fitur baru dari GitHub

Saat ada update di repo:

```bash
cd /opt/creativepos
sudo bash update.sh
```

```powershell
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File update.ps1
```

Skrip update akan:
1. `git pull` versi terbaru
2. Rebuild container Docker
3. Jalankan migrasi database baru
4. Refresh cache config
5. (Opsional) unduh APK release terbaru

### 5.3 Menambah fitur baru (untuk developer)

Struktur monorepo:

```
backend/app/Modules/     ← modul Laravel (POS, Inventory, CRM, ...)
frontend/src/app/        ← halaman Next.js
flutter_app/lib/         ← layar mobile
```

**Alur menambah fitur:**

```
1. Backend  → buat migration, model, controller, route di Modules/
2. Frontend → tambah halaman di src/app/(dashboard)/
3. Mobile   → tambah screen + API client di flutter_app/
4. Test     → php artisan test, npm run build
5. Deploy   → git push → update.sh di server
```

Contoh modul yang sudah ada:

| Modul | Route web | API prefix |
|-------|-----------|------------|
| POS | `/pos` | `/api/v1/pos/*` |
| Inventori | `/inventory` | `/api/v1/inventory/*` |
| Member | `/members` | `/api/v1/members/*` |
| KDS | `/kitchen` | `/api/v1/kitchen/*` |
| CRM | `/crm` | `/api/v1/crm/*` |
| Laporan | `/reports` | `/api/v1/reports/*` |

Dokumentasi arsitektur: [TAHAP-3/01-architecture-overview.md](./TAHAP-3/01-architecture-overview.md)

### 5.4 Menambah metode bayar POS (tanpa gateway online)

Metode bayar di kasir (Cash, Transfer BCA, QRIS, GoPay, dll.) dikelola lewat UI:

**Pengaturan → Bisnis → Metode Pembayaran POS** → centang yang diinginkan → Simpan.

Daftar metode tersedia didefinisikan di backend:

```
backend/app/Shared/Support/PaymentMethodCatalog.php
```

Untuk **menambah metode baru** (mis. `shopeepay`):

**Langkah 1** — tambah di `PaymentMethodCatalog.php`:

```php
['code' => 'shopeepay', 'name' => 'ShopeePay', 'type' => 'e_wallet'],
```

**Langkah 2** — tambah label di frontend `frontend/src/types/onboarding.ts`:

```ts
{ code: "shopeepay", label: "ShopeePay" },
```

**Langkah 3** — deploy update, lalu di Pengaturan centang metode baru.

> Metode POS ini untuk **pencatatan di kasir** (kasir pilih metode, opsional isi nomor referensi). Bukan otomatis charge ke e-wallet — kecuali Anda integrasikan gateway terpisah.

---

## 6. Tambah & atur payment gateway

CreativePOS punya **dua konteks pembayaran** yang berbeda:

| Konteks | Untuk apa | Diatur di mana |
|---------|-----------|----------------|
| **POS Kasir** | Transaksi harian di toko | UI: Pengaturan → Bisnis |
| **SaaS Billing** | Bayar invoice langganan CreativePOS | File: `backend/.env` + dashboard Midtrans/Xendit |

---

### 6.1 Metode bayar POS (kasir harian)

**Cara aktifkan (tanpa coding):**

1. Login sebagai Owner/Manager
2. **Pengaturan → Bisnis**
3. Bagian **Metode Pembayaran POS** — centang: Cash, Transfer BCA, QRIS, GoPay, OVO, dll.
4. Klik **Simpan Profil Bisnis**

Metode yang dicentang akan muncul di layar bayar POS (web & Android).

**Cara kerja di kasir:**

- **Cash** — input uang diterima, hitung kembalian
- **Transfer / QRIS / E-Wallet** — kasir pilih metode, bisa isi nomor referensi manual
- **Split payment** — bisa bayar dengan 2+ metode sekaligus

---

### 6.2 Payment gateway Midtrans (SaaS Billing)

Digunakan untuk pembayaran **invoice langganan**: VA BCA/BNI/BRI, QRIS, GoPay, OVO, DANA.

#### Langkah 1 — Daftar & ambil API key

1. Buat akun di [Midtrans Dashboard](https://dashboard.midtrans.com)
2. Ambil **Server Key** dan **Client Key** (Sandbox untuk uji, Production untuk live)

#### Langkah 2 — Set di server

Edit `backend/.env` di server:

```bash
cd /opt/creativepos
sudo nano backend/.env
```

Tambahkan / ubah:

```env
MIDTRANS_SERVER_KEY=SB-Mid-server-xxxxxxxx
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxxxxxxx
MIDTRANS_IS_PRODUCTION=false
```

| Mode | `MIDTRANS_IS_PRODUCTION` |
|------|--------------------------|
| Sandbox (uji) | `false` |
| Production (live) | `true` |

#### Langkah 3 — Daftarkan webhook di Midtrans

URL callback (ganti `IP-SERVER` atau domain Anda):

```
http://IP-SERVER/api/v1/webhooks/payment/midtrans
```

Jika pakai HTTPS:

```
https://domain-anda.com/api/v1/webhooks/payment/midtrans
```

Set di Midtrans Dashboard → **Settings → Configuration → Payment Notification URL**.

#### Langkah 4 — Terapkan ke container

```bash
cd /opt/creativepos/docker
docker compose -f docker-compose.client.yml exec backend php artisan config:clear
docker compose -f docker-compose.client.yml exec backend php artisan config:cache
docker compose -f docker-compose.client.yml restart backend
```

#### Langkah 5 — Uji pembayaran invoice

1. Login Owner → **Pengaturan → Langganan**
2. Pilih invoice → **Bayar**
3. Pilih metode (VA BCA, QRIS, GoPay, dll.)
4. Ikuti instruksi pembayaran yang muncul

> Jika API key belum diset, sistem menjalankan **mode mock** (simulasi) untuk development.

---

### 6.3 Payment gateway Xendit (kartu kredit & recurring)

Digunakan untuk **kartu kredit** dan **langganan otomatis** (auto-renew).

#### Langkah 1 — Daftar & ambil API key

1. Buat akun di [Xendit Dashboard](https://dashboard.xendit.co)
2. Ambil **Secret Key** (test atau live)
3. Buat **Webhook Verification Token**

#### Langkah 2 — Set di server

Edit `backend/.env`:

```env
XENDIT_SECRET_KEY=xnd_development_xxxxxxxx
XENDIT_WEBHOOK_TOKEN=token_webhook_anda
```

#### Langkah 3 — Daftarkan webhook di Xendit

URL:

```
http://IP-SERVER/api/v1/webhooks/payment/xendit
```

Set di Xendit Dashboard → **Settings → Webhooks** → event `invoice.paid`.

#### Langkah 4 — Terapkan & uji

Sama seperti Midtrans (config:clear → config:cache → restart backend).

Uji via **Pengaturan → Langganan → Bayar → Kartu Kredit**.

Untuk **langganan otomatis**, centang opsi recurring saat bayar invoice pertama dengan kartu kredit.

---

### 6.4 Ringkasan env payment gateway

| Variabel | Gateway | Keterangan |
|----------|---------|------------|
| `MIDTRANS_SERVER_KEY` | Midtrans | Wajib untuk charge VA/QRIS/e-wallet |
| `MIDTRANS_CLIENT_KEY` | Midtrans | Untuk Snap/frontend (jika dipakai) |
| `MIDTRANS_IS_PRODUCTION` | Midtrans | `true` = live |
| `XENDIT_SECRET_KEY` | Xendit | Wajib untuk kartu kredit |
| `XENDIT_WEBHOOK_TOKEN` | Xendit | Verifikasi webhook |
| `APP_URL` | Keduanya | Dasar URL webhook — harus bisa diakses dari internet untuk callback |

**Penting untuk webhook:** Midtrans/Xendit harus bisa **mengakses URL server Anda**. Jika server hanya di LAN (IP privat), webhook tidak akan masuk — gunakan domain publik + HTTPS, atau tunnel (ngrok) saat uji.

---

### 6.5 Cek status integrasi

Via API (setelah login):

```
GET /api/v1/settings/integrations
```

Atau lihat di **Pengaturan → Integrasi** — status Midtrans/Xendit aktif jika key sudah terisi di `backend/.env`.

---

### 6.6 Menambah metode billing gateway baru (developer)

File terkait:

| File | Fungsi |
|------|--------|
| `backend/app/Modules/Billing/Enums/BillingPaymentMethod.php` | Daftar metode billing |
| `backend/app/Modules/Billing/Services/Gateways/MidtransGateway.php` | Integrasi Midtrans |
| `backend/app/Modules/Billing/Services/Gateways/XenditGateway.php` | Integrasi Xendit |
| `backend/app/Modules/Billing/Services/PaymentService.php` | Routing metode → gateway |
| `backend/config/creativepos.php` | Config key & URL webhook |

Alur menambah gateway baru (mis. Duitku):

1. Buat class `DuitkuGateway.php` di `Services/Gateways/`
2. Tambah enum di `BillingPaymentMethod`
3. Update `PaymentService::initiatePayment()` untuk routing
4. Tambah route webhook di `Routes/api.php`
5. Tambah env di `backend/.env.example`
6. Deploy & uji

---

## 7. Update & maintenance

### Update rutin

```bash
cd /opt/creativepos && sudo bash update.sh
```

### Perintah operasional

```bash
cd /opt/creativepos/docker

# Lihat log backend
docker compose -f docker-compose.client.yml logs -f backend

# Restart semua layanan
docker compose -f docker-compose.client.yml restart

# Backup database
docker compose -f docker-compose.client.yml exec mysql \
  mysqldump -u creativepos -p creativepos > backup-$(date +%Y%m%d).sql

# Migrasi manual
docker compose -f docker-compose.client.yml exec backend php artisan migrate --force
```

### Backup file penting

| File | Isi |
|------|-----|
| `backend/.env` | API key, DB password, payment gateway |
| `docker/.env` | IP server, kredensial MySQL |
| Volume Docker `mysql_data` | Seluruh data transaksi |

---

## 8. Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Tidak bisa akses dari tablet | Pastikan satu WiFi/LAN; cek firewall port 80 |
| IP server berubah | `bash scripts/reconfigure-host.sh` |
| Health check gagal | `docker compose ps` — tunggu 1–2 menit setelah install |
| Gambar produk tidak muncul | `docker compose exec backend php artisan storage:link` |
| Metode bayar tidak muncul di POS | Pengaturan → Bisnis → centang metode → Simpan |
| Webhook payment tidak masuk | Pastikan `APP_URL` bisa diakses publik; cek URL di dashboard Midtrans/Xendit |
| Email tidak terkirim | Pengaturan → Integrasi → SMTP (Gmail butuh App Password) |
| WhatsApp gagal | Pengaturan → Integrasi → token Fonnte/Wablas/Meta |
| Update gagal | `git status` — pastikan tidak ada konflik; backup `.env` dulu |

---

## Referensi

- [CLIENT-INSTALL.md](./CLIENT-INSTALL.md) — instalasi server detail
- [ANDROID-APP.md](./ANDROID-APP.md) — build & pasang APK
- [TAHAP-3/04-api-documentation.md](./TAHAP-3/04-api-documentation.md) — dokumentasi API
- [TAHAP-1/03-feature-list.md](./TAHAP-1/03-feature-list.md) — daftar fitur lengkap

---

*CreativePOS by Creative Network*