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
8. [Integrasi Email & WhatsApp](#8-integrasi-email--whatsapp)
9. [HTTPS & domain publik](#9-https--domain-publik)
10. [Printer thermal](#10-printer-thermal)
11. [Akun demo & Super Admin](#11-akun-demo--super-admin)
12. [Panel Platform Admin](#12-panel-platform-admin)
13. [Build APK dari source](#13-build-apk-dari-source)
14. [Import produk massal (CSV)](#14-import-produk-massal-csv)
15. [Troubleshooting](#15-troubleshooting)

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

## 8. Integrasi Email & WhatsApp

Konfigurasi di **Pengaturan → Integrasi** (login sebagai Owner/Manager).

### 8.1 Gateway Email (SMTP)

#### Kapan diperlukan

- Email selamat datang saat pendaftaran
- OTP login / verifikasi
- Reset password
- Notifikasi transaksi (jika diaktifkan)

#### Langkah konfigurasi (UI)

1. Buka `http://IP-SERVER/settings` → tab **Integrasi**
2. Bagian **Gateway Email (SMTP)**:
   - Centang **Aktifkan gateway email**
   - Mode: **SMTP** (bukan Log)
3. Isi field SMTP
4. Klik **Simpan Gateway Email**
5. Uji: isi email penerima → **Simpan & Kirim Uji**

#### Contoh Gmail (Google Workspace / Gmail pribadi)

| Field | Nilai |
|-------|-------|
| SMTP Host | `smtp.gmail.com` |
| Port | `587` |
| Enkripsi | TLS |
| Username | email Gmail Anda |
| Password | **App Password** (bukan password login biasa) |
| From Address | `noreply@domainanda.com` |
| From Name | Nama bisnis |

Cara buat App Password Gmail:

1. Google Account → **Keamanan** → aktifkan **Verifikasi 2 Langkah**
2. **Kata sandi aplikasi** → buat untuk "Mail"
3. Salin 16 karakter → paste ke field Password di CreativePOS

#### Contoh Mailtrap (uji coba)

| Field | Nilai |
|-------|-------|
| Host | `sandbox.smtp.mailtrap.io` |
| Port | `587` |
| Enkripsi | TLS |
| Username / Password | dari inbox Mailtrap |

#### Mode Log (development)

Jika SMTP belum siap, pilih mode **Log** — email tidak dikirim ke luar, tetapi dicatat di:

```bash
cd /opt/creativepos/docker
docker compose -f docker-compose.client.yml logs -f backend | grep -i mail
```

#### Troubleshooting email

| Gejala | Penyebab | Solusi |
|--------|----------|--------|
| Uji sukses tapi tidak masuk inbox | Masuk spam / From tidak valid | Cek folder spam; set From Address domain valid |
| Authentication failed | Password salah / bukan App Password | Gmail wajib App Password |
| Connection timeout | Port/firewall diblokir | Coba port 587 + TLS |
| Checkbox aktif tidak dicentang | Gateway nonaktif | Centang "Aktifkan gateway email" |

---

### 8.2 Integrasi WhatsApp

Mendukung **Fonnte**, **Wablas**, dan **Meta WhatsApp Business API**.

#### Langkah konfigurasi (UI)

1. **Pengaturan → Integrasi → Integrasi WhatsApp**
2. Centang **Aktifkan integrasi WhatsApp**
3. Pilih **Gateway**
4. Isi **Nomor WhatsApp Pengirim** (format `628xxxxxxxxxx`, tanpa `+`)
5. Isi **API Token**
6. **Simpan Integrasi**
7. Uji: nomor penerima format `08xxxxxxxxxx` → **Simpan & Kirim Uji**

#### Fonnte (paling mudah untuk UMKM)

1. Daftar di [fonnte.com](https://fonnte.com)
2. Hubungkan device WhatsApp (scan QR)
3. Salin **API Token** dari dashboard Fonnte
4. Di CreativePOS:
   - Gateway: **Fonnte**
   - Nomor pengirim: nomor device Fonnte (`628...`)
   - Token: paste token Fonnte

#### Wablas

| Field | Nilai |
|-------|-------|
| Gateway | Wablas |
| API URL | `https://DOMAIN.wablas.com` (dari dashboard Wablas) |
| Token | API key Wablas |
| Nomor pengirim | `628...` |

#### Meta (WhatsApp Business API)

| Field | Nilai |
|-------|-------|
| Gateway | Meta |
| API URL | `https://graph.facebook.com/v21.0/{phone-number-id}/messages` |
| Token | Permanent access token Meta |
| Nomor pengirim | Phone number ID terdaftar |

#### Mode dev (token belum aktif)

Jika token kosong atau integrasi nonaktif, pesan **tidak dikirim ke WhatsApp** tetapi dicatat di log server. UI menampilkan: *"Mode dev: pesan dicatat di log server"*.

#### Troubleshooting WhatsApp

| Gejala | Solusi |
|--------|--------|
| Token ditolak | Pastikan token baru (bukan `••••`); simpan ulang |
| Nomor penerima invalid | Format uji: `08xxxxxxxxxx` (8–13 digit) |
| Pesan ke "chat diri sendiri" | Nomor penerima jangan sama dengan device Fonnte |
| Integrasi nonaktif | Centang "Aktifkan integrasi WhatsApp" |

---

## 9. HTTPS & domain publik

Instalasi default memakai **HTTP port 80**. HTTPS diperlukan jika:

- Payment gateway webhook (Midtrans/Xendit) dari internet
- Akses dari luar LAN
- Keamanan data di production

### 9.1 Persiapan domain

1. Beli / atur domain (mis. `pos.toko-saya.com`)
2. Arahkan **A record** DNS ke IP publik server
3. Pastikan port **80** dan **443** terbuka di router/firewall

### 9.2 Generate sertifikat Let's Encrypt (Ubuntu)

```bash
# Hentikan nginx sementara agar port 80 bebas
cd /opt/creativepos/docker
docker compose -f docker-compose.client.yml stop nginx

sudo apt-get install -y certbot
sudo certbot certonly --standalone -d pos.toko-saya.com --agree-tos -m admin@toko-saya.com

# Sertifikat ada di:
# /etc/letsencrypt/live/pos.toko-saya.com/fullchain.pem
# /etc/letsencrypt/live/pos.toko-saya.com/privkey.pem
```

### 9.3 Aktifkan HTTPS di CreativePOS

**Langkah 1** — salin template nginx SSL:

```bash
cd /opt/creativepos/docker/nginx
cp client-ssl.conf.example client-ssl.conf
nano client-ssl.conf   # ganti DOMAIN_ANDA.com → pos.toko-saya.com
```

**Langkah 2** — mount sertifikat & config SSL di `docker-compose.client.yml` (service `nginx`):

```yaml
ports:
  - "${APP_PORT:-80}:80"
  - "443:443"
volumes:
  - ./nginx/client-ssl.conf:/etc/nginx/conf.d/default.conf:ro
  - ./nginx/proxy-params.conf:/etc/nginx/conf.d/proxy-params.conf:ro
  - ../backend/storage/app/public:/var/www/storage:ro
  - /etc/letsencrypt:/etc/letsencrypt:ro
```

**Langkah 3** — update environment:

```bash
cd /opt/creativepos
sudo bash scripts/reconfigure-host.sh pos.toko-saya.com 443
```

Atau edit manual `backend/.env`:

```env
APP_URL=https://pos.toko-saya.com
FRONTEND_URL=https://pos.toko-saya.com
REVERB_SCHEME=https
REVERB_PORT=443
SANCTUM_STATEFUL_DOMAINS=pos.toko-saya.com,localhost,127.0.0.1
```

**Langkah 4** — terapkan:

```bash
cd /opt/creativepos/docker
docker compose -f docker-compose.client.yml up -d
docker compose -f docker-compose.client.yml exec backend php artisan config:cache
```

**Langkah 5** — verifikasi:

```bash
curl -I https://pos.toko-saya.com/api/v1/health
```

### 9.4 Perpanjang sertifikat otomatis

```bash
sudo crontab -e
```

Tambahkan:

```cron
0 3 * * * certbot renew --quiet && cd /opt/creativepos/docker && docker compose -f docker-compose.client.yml restart nginx
```

### 9.5 Webhook payment dengan HTTPS

Setelah HTTPS aktif, update URL di dashboard Midtrans/Xendit:

```
https://pos.toko-saya.com/api/v1/webhooks/payment/midtrans
https://pos.toko-saya.com/api/v1/webhooks/payment/xendit
```

---

## 10. Printer thermal

CreativePOS mendukung printer **ESC/POS 58mm & 80mm**.

| Platform | Metode cetak |
|----------|--------------|
| **Web (browser)** | Print dialog browser (`window.print`) — thermal via driver OS |
| **Android (Flutter)** | Bluetooth ESC/POS langsung |

### 10.1 Printer di web (PC kasir)

1. Selesaikan transaksi di `/pos`
2. Klik **Cetak Struk** pada dialog pembayaran
3. Browser membuka dialog print
4. Pilih printer thermal yang sudah terinstall di Windows
5. Atur ukuran kertas 58mm atau 80mm di preferensi printer

**Tips Windows:**

- Install driver printer thermal (Epson, Iware, Zjiang, dll.)
- Set sebagai printer default
- Chrome: `Ctrl+P` → More settings → Paper size

### 10.2 Printer Bluetooth di Android (Flutter)

1. **Pair printer dulu** di Pengaturan Android → Bluetooth
2. Buka app CreativePOS → **Pengaturan** → **Printer**
3. Tap **Izinkan Bluetooth** (grant permission)
4. Tap **Scan Printer** — pilih printer dari daftar paired
5. Pilih **Lebar kertas**: 58mm atau 80mm
6. Aktifkan **Cetak otomatis** (opsional)
7. Tap **Simpan**
8. Tap **Test Print** untuk uji

**Lokasi di app:** Pengaturan → Printer → Template Struk (kustomisasi header/footer).

### 10.3 Troubleshooting printer

| Masalah | Solusi |
|---------|--------|
| Printer Bluetooth tidak muncul | Pair dulu di Settings Android; restart Bluetooth |
| Permission ditolak | Beri izin Bluetooth + Lokasi (Android 12+) |
| Struk kosong / gibberish | Pastikan lebar kertas 58/80mm sesuai printer |
| Web print blank | Pop-up blocker — izinkan pop-up untuk IP server |
| Koneksi putus | Printer dekat device; cek baterai printer |

---

## 11. Akun demo & Super Admin

### 11.1 Akun default (otomatis saat install)

Setelah `install.sh` / `migrate --seed`, dua akun siap dipakai:

| Akun | Email | Password | Akses |
|------|-------|----------|-------|
| **Admin Toko** | `admin@creativepos.local` | `Admin123!` | Beberapa fitur (role **Manager**) |
| **Super Admin** | `superadmin@creativepos.local` | `SuperAdmin123!` | **Semua fitur** + panel `/platform` |

**Admin Toko** (`manager`) — bisa:

- Dashboard, POS, inventori (lihat/tambah/edit), laporan, CRM, delivery, reservasi
- Pengaturan (lihat, terbatas)

**Tidak bisa:** hapus produk, kelola semua user, ubah outlet, void/refund penuh seperti owner.

**Super Admin** — bisa:

- Semua menu (POS, inventori, laporan, CRM, delivery, dll.)
- Panel **Platform** (`/platform`) — kelola tenant, upload APK, MRR
- Bypass permission di backend

> **Production:** wajib ganti password! Set env sebelum install:
> `CREATIVEPOS_DEMO_ADMIN_PASSWORD`, `CREATIVEPOS_SUPER_ADMIN_PASSWORD`
> atau `SKIP_DEFAULT_ACCOUNTS=1` untuk lewati akun demo.

Login: `http://IP-SERVER/login`

### 11.2 Akun bisnis tambahan (Owner baru)

Untuk bisnis kedua / mandiri tanpa akun demo:

1. Buka `http://IP-SERVER/register`
2. Isi nama bisnis, nama owner, email, password
3. Login → Anda menjadi **Owner** tenant baru

### 11.3 Data demo setelah register

Seeder demo (`DashboardDemoSeeder`, dll.) berjalan saat **install**, sebelum ada tenant. Jadi pada instalasi normal **produk demo tidak otomatis muncul**.

Untuk mengisi data contoh setelah register (opsional):

```bash
cd /opt/creativepos/docker

# Lihat tenant_id (biasanya 1 untuk bisnis pertama)
docker compose -f docker-compose.client.yml exec -T mysql \
  mysql -u creativepos -p"${DB_PASSWORD}" creativepos \
  -e "SELECT id, name, slug FROM tenants;"

# (Disarankan) Import produk dulu agar demo delivery punya item — lihat bagian 14

# Muat data demo operasional (reservasi, delivery, driver, QR menu, CRM, invoice)
docker compose -f docker-compose.client.yml exec -T backend php artisan db:seed --class=OperationsDemoSeeder
docker compose -f docker-compose.client.yml exec -T backend php artisan db:seed --class=QrMenuSeeder
docker compose -f docker-compose.client.yml exec -T backend php artisan db:seed --class=CrmDemoSeeder
docker compose -f docker-compose.client.yml exec -T backend php artisan db:seed --class=BillingDemoSeeder
```

**Catatan penting:**

- `DashboardDemoSeeder` (produk + transaksi demo) **tidak jalan** setelah `/register` karena outlet sudah dibuat otomatis.
- Untuk produk massal setelah register → gunakan **import CSV** (bagian 14) atau tambah manual di **Inventori**.
- Seeder demo bersifat **idempotent** — aman dijalankan ulang; data yang sudah ada dilewati.

### 11.4 Akun driver demo (jika OperationsDemoSeeder dijalankan)

| Email | Password | Peran |
|-------|----------|-------|
| `driver1@{slug-bisnis}.demo` | `password` | Driver |
| `driver2@{slug-bisnis}.demo` | `password` | Driver |

Ganti `{slug-bisnis}` dengan slug tenant (mis. bisnis "Warung Makan" → `warung-makan`).

### 11.5 Buat / reset Super Admin manual

Super Admin mengelola seluruh tenant, paket, dan upload APK.

```bash
cd /opt/creativepos/docker

docker compose -f docker-compose.client.yml exec -T backend \
  php scripts/create-super-admin.php admin@creativepos.local "PasswordKuat123!"
```

| Field | Nilai |
|-------|-------|
| Email | `admin@creativepos.local` (ganti sesuai kebutuhan) |
| Password | minimal 8 karakter |

Login:

1. Buka `http://IP-SERVER/login`
2. Masuk dengan email/password Super Admin
3. Buka `http://IP-SERVER/platform`

> Super Admin **bukan** tenant owner — `tenant_id` kosong, role `super-admin`.

---

## 12. Panel Platform Admin

Hanya untuk user dengan `is_super_admin = true`. URL: `http://IP-SERVER/platform`

### 12.1 Fitur dashboard

| Bagian | Fungsi |
|--------|--------|
| **KPI** | MRR, jumlah tenant aktif, trial, invoice |
| **Daftar Tenant** | Lihat semua bisnis terdaftar |
| **Suspend / Aktifkan** | Tangguhkan atau aktifkan tenant bermasalah |
| **Upload APK** | Publish versi mobile baru ke semua client |
| **Daftar Release** | Riwayat build APK, aktifkan/nonaktifkan versi |

### 12.2 Upload APK via Platform Admin

1. Login Super Admin → `/platform`
2. Bagian **Mobile Release**
3. Isi **Version** (mis. `1.3.1`) dan **Build** (mis. `18`)
4. Pilih file `.apk`
5. Centang **Mandatory** jika update wajib
6. Klik **Upload**

HP Android akan mendeteksi versi baru via:

```
GET /api/v1/mobile/version?platform=android
```

### 12.3 Upload APK via CLI (alternatif)

Tanpa login UI:

```bash
cd /opt/creativepos/docker

docker compose -f docker-compose.client.yml exec -T backend \
  php scripts/publish-apk.php \
  /var/www/html/storage/app/uploads/path/to/app-release.apk \
  1.3.1 18 "Catatan rilis" 0
```

### 12.4 Suspend tenant

Di `/platform` → daftar tenant → **Tangguhkan**. Tenant yang ditangguhkan tidak bisa login sampai diaktifkan kembali.

---

## 13. Build APK dari source

### 13.1 Persyaratan (mesin development)

| Tool | Versi |
|------|-------|
| Flutter SDK | 3.24+ stable |
| Android SDK | API 34 |
| JDK | 17 |
| Android Studio | Terbaru (SDK Manager) |

### 13.2 Setup sekali (Windows)

```powershell
cd D:\pos
powershell -ExecutionPolicy Bypass -File scripts\setup-flutter.ps1
```

### 13.3 Build APK

```powershell
# Debug (uji internal)
powershell -ExecutionPolicy Bypass -File scripts\build-flutter-android.ps1

# Release (production, multi-ABI)
powershell -ExecutionPolicy Bypass -File scripts\build-flutter-android.ps1 -Release

# App Bundle (Google Play)
powershell -ExecutionPolicy Bypass -File scripts\build-flutter-android.ps1 -Bundle
```

Output: `flutter_app/dist/*.apk`

### 13.4 Build manual (tanpa script)

```bash
cd flutter_app
flutter pub get
flutter test
flutter build apk --release --split-per-abi
```

| Build | Lokasi output |
|-------|---------------|
| Debug | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release arm64 | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` |

### 13.5 Signing release (Play Store / production)

```bash
keytool -genkey -v -keystore creativepos-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias creativepos
cp android/key.properties.example android/key.properties
# Edit key.properties dengan password keystore
flutter build apk --release
```

Detail lengkap: [flutter_app/docs/BUILD_ANDROID.md](../flutter_app/docs/BUILD_ANDROID.md)

### 13.6 Publish APK ke server client

**Opsi A — GitHub Release (otomatis saat update.sh):**

```bash
git tag v1.3.1-18
git push origin v1.3.1-18
# GitHub Actions build & release APK
```

**Opsi B — Upload manual ke server:**

```bash
# Copy APK ke server
scp flutter_app/dist/app-arm64-v8a-release.apk user@10.110.1.15:/tmp/

# Publish
ssh user@10.110.1.15
cd /opt/creativepos/docker
docker compose -f docker-compose.client.yml exec -T backend \
  php scripts/publish-apk.php /tmp/app-arm64-v8a-release.apk 1.3.1 18
```

**Opsi C — Platform Admin UI:** lihat bagian 12.

---

## 14. Import produk massal (CSV)

Untuk ratusan/ribuan SKU — gunakan skrip import CSV (terverifikasi, tidak lewat UI).

### 14.1 Format CSV

Template: [`docs/templates/products-import.csv`](./templates/products-import.csv)

| Kolom | Wajib | Contoh | Keterangan |
|-------|-------|--------|------------|
| `name` | Ya | Nasi Goreng | Nama produk |
| `sku` | Ya | NGS-001 | Unik per tenant |
| `base_price` | Ya | 25000 | Harga jual |
| `cost_price` | Tidak | 10000 | Harga modal |
| `barcode` | Tidak | 8991234567890 | Untuk scan POS |
| `category_name` | Tidak | Makanan | Dibuat otomatis jika belum ada |
| `initial_stock` | Tidak | 50 | Stok awal |
| `min_stock` | Tidak | 10 | Alert stok menipis |
| `track_stock` | Tidak | 1 | `1`/`0` — lacak stok |

### 14.2 Langkah import (server Linux)

```bash
cd /opt/creativepos

# 1. Salin CSV ke folder storage backend
mkdir -p backend/storage/app/import
cp docs/templates/products-import.csv backend/storage/app/import/products.csv
# Edit products.csv sesuai data Anda (Excel → Save As CSV UTF-8)

# 2. Pastikan sudah ada tenant (register dulu di /register)
cd docker
docker compose -f docker-compose.client.yml exec -T mysql \
  mysql -u creativepos -p creativepos -e "SELECT id, name FROM tenants;"

# 3. Jalankan import (tenant_id=1 untuk bisnis pertama)
docker compose -f docker-compose.client.yml exec -T backend \
  php scripts/import-products-csv.php /var/www/html/storage/app/import/products.csv 1
```

Output sukses:

```
Import selesai untuk tenant #1 (Nama Bisnis)
Berhasil : 4
Dilewati : 0
```

### 14.3 Import via Excel

1. Buka template CSV di Excel / Google Sheets
2. Isi data produk
3. **Save As → CSV UTF-8** (bukan .xlsx langsung)
4. Upload ke server → jalankan skrip seperti di atas

### 14.4 Aturan & batasan

- SKU duplikat **dilewati** (tidak menimpa produk lama)
- Melebihi limit paket (`max_products`) → error dari sistem
- Kategori dibuat otomatis berdasarkan `category_name`
- Stok awal masuk ke **gudang default** outlet

### 14.5 Alternatif: tambah manual (sedikit produk)

**Inventori → Produk → Tambah Produk** di web, atau scan/tambah di app Android tab **Toko**.

---

## 15. Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Tidak bisa akses dari tablet | Pastikan satu WiFi/LAN; cek firewall port 80 |
| IP server berubah | `bash scripts/reconfigure-host.sh` |
| Health check gagal | `docker compose ps` — tunggu 1–2 menit setelah install |
| Gambar produk tidak muncul | `docker compose exec backend php artisan storage:link` |
| Metode bayar tidak muncul di POS | Pengaturan → Bisnis → centang metode → Simpan |
| Webhook payment tidak masuk | HTTPS + `APP_URL` publik; cek URL Midtrans/Xendit |
| Email tidak terkirim | SMTP aktif; Gmail pakai App Password; cek log backend |
| WhatsApp gagal | Token valid; format nomor benar; integrasi diaktifkan |
| HTTPS certificate error | Periksa mount `/etc/letsencrypt`; renew certbot |
| Printer BT gagal | Pair di Android; izin Bluetooth; lebar kertas 58/80mm |
| Import CSV gagal | Header wajib: name,sku,base_price; encoding UTF-8 |
| Super Admin 403 | Jalankan `create-super-admin.php`; login ulang |
| Update gagal | `git status` — backup `.env`; resolve conflict dulu |

---

## Referensi

- [CLIENT-INSTALL.md](./CLIENT-INSTALL.md) — instalasi server detail
- [ANDROID-APP.md](./ANDROID-APP.md) — build & pasang APK
- [flutter_app/docs/BUILD_ANDROID.md](../flutter_app/docs/BUILD_ANDROID.md) — signing & Play Store
- [templates/products-import.csv](./templates/products-import.csv) — template import produk
- [TAHAP-3/04-api-documentation.md](./TAHAP-3/04-api-documentation.md) — dokumentasi API
- [TAHAP-1/03-feature-list.md](./TAHAP-1/03-feature-list.md) — daftar fitur lengkap

---

*CreativePOS by Creative Network*