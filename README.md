# CreativePOS

**Smart Business Management Platform**

> Multi-Tenant SaaS POS & Business Management System  
> by [Creative Network](https://creativenetwork.id)

---

## Overview

CreativePOS adalah platform SaaS enterprise siap pasar untuk bisnis F&B dan retail: restoran, kafe, coffee shop, retail, minimarket, UMKM, dan franchise.

**Fitur lengkap:**
- POS Terminal & Shift Kasir
- Inventori & Manajemen Stok (import stok massal CSV/Excel)
- Loyalty Member & Wallet
- QR Menu Digital & Kitchen Display (KDS)
- Reservasi Meja & Delivery Order
- CRM Tiket & WhatsApp Integration
- Laporan Bisnis & Ekspor CSV
- Langganan SaaS & Billing Invoice
- Platform Admin (Super Admin)

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Laravel 12, PHP 8.4, MySQL 8, Redis, Sanctum |
| Frontend | Next.js 16, React, TypeScript, TailwindCSS, React Query, Zustand |
| Deployment | Docker, Docker Compose, Nginx |

---

## Instalasi Server dari GitHub

Docker, Docker Compose, dan Git **diinstall otomatis** oleh skrip.

### Ubuntu — server kosong (1 baris)

```bash
curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash
# IP opsional: ... | sudo bash -s -- 10.110.1.15
```

### Ubuntu — sudah ada Git

```bash
sudo git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
cd /opt/creativepos
sudo bash install.sh
```

### Windows — Administrator (Docker Desktop auto-install)

```powershell
# PowerShell sebagai Administrator
irm https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.ps1 | iex
```

Atau:

```powershell
git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git D:\creativepos
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File install.ps1 -AppHost 10.110.1.15
```

### Update

```bash
cd /opt/creativepos && sudo bash update.sh
```

| Setelah install | URL / Akun |
|-----------------|------------|
| Login | `http://IP-SERVER/login` |
| Admin Toko | `admin@creativepos.local` / `Admin123!` |
| Super Admin | `superadmin@creativepos.local` / `SuperAdmin123!` |
| Web POS | `http://IP-SERVER/pos` |
| Platform | `http://IP-SERVER/platform` |
| Daftar bisnis baru | `http://IP-SERVER/register` |
| APK mobile | `http://IP-SERVER/api/v1/mobile/version?platform=android` |

Panduan lengkap: [docs/CLIENT-INSTALL.md](docs/CLIENT-INSTALL.md) · [docs/TUTORIAL-LENGKAP.md](docs/TUTORIAL-LENGKAP.md) (setup → aktif → fitur → payment gateway) · [docs/MODUL-DAN-FITUR.md](docs/MODUL-DAN-FITUR.md) (katalog modul web & mobile)

**Repo private:** set `GITHUB_TOKEN` (PAT dengan scope `repo`) sebelum `git clone`.

## Aplikasi Android

### Flutter (Native — Recommended)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\setup-flutter.ps1
cd flutter_app
flutter run
```

Panduan: [flutter_app/README.md](flutter_app/README.md)

### Capacitor (Web Wrapper — Legacy)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build-android.ps1
```

Panduan: [docs/ANDROID-APP.md](docs/ANDROID-APP.md)

---

## Quick Start (Docker — Recommended)

```bash
cd D:\pos\docker
docker compose up -d
docker compose exec backend php artisan migrate --seed

cd D:\pos\frontend
cp .env.local.example .env.local   # set NEXT_PUBLIC_API_URL
npm install
npm run dev
```

Buka http://localhost:3000

**Demo login:** Daftar akun baru di `/register` (trial 14 hari otomatis).

---

## Manual Setup

### Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

---

## Subscription Packages

| Package | Harga/bulan | Target |
|---------|-------------|--------|
| **Starter** | Rp 99.000 | UMKM, 1 outlet, 3 user |
| **Business** | Rp 299.000 | Bisnis berkembang, 3 outlet, 10 user |
| **Enterprise** | Rp 799.000 | Multi-outlet, CRM & WhatsApp penuh |

Trial gratis 14 hari untuk semua paket.

---

## Aplikasi Routes

| Route | Modul |
|-------|-------|
| `/` | Landing page + pricing |
| `/login`, `/register` | Autentikasi |
| `/dashboard` | KPI & analitik |
| `/pos` | Point of Sale |
| `/kitchen` | Kitchen Display System |
| `/reservations` | Reservasi meja |
| `/delivery` | Manajemen delivery |
| `/inventory` | Produk & stok |
| `/members` | Loyalty & wallet |
| `/crm` | Tiket customer service |
| `/reports` | Laporan bisnis |
| `/settings` | Pengaturan & langganan |
| `/platform` | Super Admin dashboard |
| `/menu/{tenant}/{outlet}` | QR Menu publik |

---

## Development Phases

| Tahap | Status |
|-------|--------|
| TAHAP 1 — Requirements | ✅ Selesai |
| TAHAP 2 — Database Design (156 tabel) | ✅ Selesai |
| TAHAP 3 — Architecture & Docker | ✅ Selesai |
| TAHAP 4 — Source Code (9 modul) | ✅ Selesai |

Detail implementasi: [`docs/TAHAP-4/README.md`](docs/TAHAP-4/README.md)

---

## Production Deployment

```bash
# 1. Set environment variables
#    backend/.env: APP_URL, DB_*, REDIS_*, SANCTUM_STATEFUL_DOMAINS
#    frontend/.env.local: NEXT_PUBLIC_API_URL

# 2. Build & deploy
cd docker
docker compose -f docker-compose.yml up -d --build

# 3. Run migrations
docker compose exec backend php artisan migrate --force
docker compose exec backend php artisan config:cache
docker compose exec backend php artisan route:cache

# 4. Build frontend for production
cd ../frontend
npm run build
npm start
```

Nginx reverse proxy dikonfigurasi di `docker/nginx/default.conf`.

---

## Project Structure

```
D:\pos\
├── backend/          # Laravel 12 API (modular)
├── frontend/         # Next.js 16 App
├── docker/           # Docker Compose + Nginx
├── docs/
│   ├── TAHAP-1/      # Requirement Analysis
│   ├── TAHAP-2/      # Database Design
│   ├── TAHAP-3/      # Architecture Design
│   └── TAHAP-4/      # Implementation Progress
└── README.md
```

---

## License

Proprietary — Creative Network © 2026