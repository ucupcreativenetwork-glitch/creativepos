# Modul & Fitur CreativePOS

Katalog lengkap modul web, aplikasi Android (Flutter), dan API backend — termasuk matriks ketersediaan dan celah paritas.

Panduan operasional: [TUTORIAL-LENGKAP.md](./TUTORIAL-LENGKAP.md) · Instalasi: [CLIENT-INSTALL.md](./CLIENT-INSTALL.md)

---

## Ringkasan Platform

CreativePOS adalah sistem POS multi-tenant untuk F&B dan retail. Satu server bisa melayani banyak bisnis (tenant). Setiap tenant punya paket langganan, pengguna dengan role berbeda, dan fitur yang bisa diaktifkan/nonaktifkan.

| Lapisan | Teknologi |
|---------|-----------|
| Backend API | Laravel 12, PHP 8.4, MySQL, Redis |
| Web | Next.js 16, React, TypeScript |
| Mobile | Flutter (Android) |
| Deploy | Docker, Nginx |

---

## Paket Langganan & Fitur

| Paket | Harga/bulan | Target | Fitur utama |
|-------|-------------|--------|-------------|
| **Starter** | Rp 99.000 | UMKM, 1 outlet | POS, inventori, loyalty, laporan dasar |
| **Business** | Rp 299.000 | Berkembang, 3 outlet | + order/KDS, reservasi, CRM |
| **Enterprise** | Rp 799.000 | Multi-outlet | + delivery, wallet, WhatsApp penuh |

Trial gratis 14 hari untuk semua paket.

### Kode fitur paket

| Kode | Modul |
|------|-------|
| `loyalty` | Member, poin, tier |
| `wallet` | Dompet digital member |
| `order` | Order meja, KDS dapur |
| `reservation` | Reservasi meja |
| `delivery` | Pengantaran |
| `crm` | Tiket & WhatsApp CS |
| `report` | Laporan bisnis (+ export) |

### Toggle tenant (owner bisa matikan)

- `feature_reservations`
- `feature_delivery`
- `feature_qr_menu`

### Super Admin

Akun `is_super_admin` bypass batas paket di web dan mengakses `/platform` (kelola tenant, paket, billing, rilis APK).

---

## Hak Akses (RBAC)

Role bawaan: `super-admin`, `owner`, `manager`, `supervisor`, `cashier`, `waiter`, `kitchen`, `driver`, `customer-service`, `customer`.

| Permission | Keterangan |
|------------|------------|
| `dashboard.view` | Lihat dashboard |
| `pos.create` / `pos.view` / `pos.void` / `pos.refund` / `pos.discount` | Operasi kasir |
| `pos.shift.open` / `pos.shift.close` | Buka/tutup shift |
| `inventory.view` / `inventory.create` / `inventory.update` / `inventory.delete` | Produk & kategori |
| `inventory.stock.adjust` | Stok masuk/keluar/sesuaikan + import massal |
| `loyalty.*` | Member & poin |
| `wallet.*` | Dompet member |
| `order.*` / `kitchen.view` | Order & dapur |
| `delivery.*` | Pengantaran |
| `reservation.*` | Reservasi |
| `crm.*` | Customer service |
| `report.view` / `report.export` | Laporan |
| `tenant.settings.*` / `tenant.users.*` / `tenant.outlets.manage` | Pengaturan bisnis |
| `platform.*` | Panel platform (super admin) |

**Catatan:** Web memfilter menu berdasarkan **paket fitur** dan **permission RBAC** (+ super admin bypass). API memvalidasi **permission** per aksi.

**Keamanan login:** akun default & staff yang diundang wajib **ganti kata sandi** saat login pertama (`/change-password`).

---

## Modul Web (`frontend`)

### Autentikasi & publik

| Route | Fitur |
|-------|-------|
| `/login` | Login |
| `/register` | Daftar tenant baru (trial 14 hari) |
| `/forgot-password`, `/reset-password/[token]` | Reset password |
| `/two-factor` | Verifikasi 2FA |
| `/` | Landing page & pricing |
| `/menu/{tenant}/{outlet}` | QR Menu tamu |
| `/menu/.../table/[token]` | QR Menu per meja |
| `/menu/track/[uuid]` | Lacak pesanan tamu |
| `/offline` | Fallback offline → redirect POS |

### Dashboard (setelah login)

| Route | Modul | Paket | Fitur utama |
|-------|-------|-------|-------------|
| `/dashboard` | Dashboard | Selalu | KPI, grafik penjualan/produk/pelanggan, live feed, checklist setup |
| `/pos` | POS | Selalu | Katalog, keranjang, modifier, barcode, shift, hold bill, pembayaran, member/poin, offline cache |
| `/pos/history` | Riwayat POS | Selalu | Daftar transaksi, void |
| `/kitchen` | KDS Dapur | `order` | Antrian dapur kanban, update status |
| `/reservations` | Reservasi | `reservation` | Daftar, kalender, buat/edit, slot waktu |
| `/delivery` | Delivery | `delivery` | Kanban order, assign driver, zona, biaya |
| `/inventory` | Inventori | Selalu | Produk, bahan baku, resep/COGS, alert stok, stok in/out/adjust, **import produk & stok CSV/Excel** |
| `/members` | Member | `loyalty` | CRUD member, tier, poin, topup/withdraw/transfer wallet |
| `/crm` | CRM | `crm` | Tiket, assign, balas, FAQ, konfigurasi WhatsApp |
| `/reports` | Laporan | `report` | Penjualan, produk, inventori, member; P&L & arus kas (paket penuh); export |
| `/settings` | Pengaturan | Selalu | Bisnis, outlet, operasional (meja/QR/slot), loyalty, user, langganan, integrasi email/WA |
| `/platform` | Platform Admin | Super admin | Tenant, paket, invoice billing, rilis APK |

---

## Modul Mobile — Flutter (`flutter_app`)

### Setup & auth

| Route | Fitur |
|-------|-------|
| `/server-setup` | Konfigurasi URL API server |
| `/standalone-setup` | Setup toko lokal tanpa server |
| `/login`, `/two-factor` | Login & 2FA |

### Tab utama (mode terhubung server)

| Route | Modul | Paket | Fitur utama |
|-------|-------|-------|-------------|
| `/dashboard` | Dashboard | Selalu | KPI, grafik, shortcut |
| `/pos` | POS | Selalu | Kasir, barcode kamera, shift, hold, checkout, offline queue, printer Bluetooth |
| `/inventory` | Inventori | Selalu | Produk, stok, alert; pergerakan stok manual |
| `/members` | Member & Layanan | `loyalty` + toggle | Hub: member, QR menu staff, permintaan meja, reservasi |
| `/settings` | Pengaturan | Selalu | Profil, biometrik, server, printer, sync, logout |

### Sub-rute

| Route | Fitur | Paket |
|-------|-------|-------|
| `/operations?tab=delivery` | Order delivery, detail, status | `delivery` |
| `/operations?tab=crm` | Tiket, FAQ, buat/balas | `crm` |
| `/operations?tab=notifications` | Notifikasi in-app + FCM | Selalu |
| `/sync` | Antrian offline, sync manual | Selalu |

### Mode standalone (tanpa server)

| Tab | Fitur |
|-----|-------|
| Kasir | POS lokal |
| Toko | Produk lokal, terima stok, CRUD |
| Pengaturan | Profil toko, printer, template struk, update app |

### Kemampuan native (mobile only)

- Printer thermal Bluetooth ESC/POS
- Login biometrik
- Push notification FCM
- Update APK OTA (`/api/v1/mobile/version`)
- Scanner barcode/QR kamera
- Geolokasi (driver delivery)
- SQLite offline & antrian sync

---

## Modul API Backend (`backend/app/Modules`)

| Modul | Prefix API | Middleware paket | Endpoint utama |
|-------|------------|------------------|----------------|
| **Auth** | `/v1/auth/*` | — | Login, logout, 2FA, invite, riwayat sesi |
| **Dashboard** | `/v1/dashboard/*` | — | KPI, grafik, live feed |
| **POS** | `/v1/pos/*` | — | Katalog, transaksi, shift, hold, void |
| **Inventory** | `/v1/inventory/*` | — | Produk, kategori, stok, bahan baku, resep, **import stok** |
| **Loyalty** | `/v1/members/*`, `/loyalty/*` | `feature:loyalty` | Member, tier, poin |
| **Wallet** | `/v1/wallet/*` | `feature:wallet` | Topup, withdraw, transfer |
| **Order** | `/v1/orders/*`, `/kitchen/*`, `/tables/*` | `feature:order` | Order, meja, KDS |
| **Order (publik)** | `/v1/public/*` | — | QR menu tamu, order, lacak, panggil pelayan |
| **Reservation** | `/v1/reservations/*` | `feature:reservation` | CRUD reservasi, slot |
| **Delivery** | `/v1/delivery/*` | `feature:delivery` | Order, driver, zona |
| **CRM** | `/v1/crm/*` | `feature:crm` | Tiket, FAQ, WhatsApp |
| **Report** | `/v1/reports/*` | `feature:report` | Laporan & export Excel/CSV |
| **Billing** | `/v1/billing/*` | — | Langganan, invoice |
| **Billing webhook** | `/v1/webhooks/payment/*` | — | Midtrans, Xendit |
| **Notification** | `/v1/notifications/*` | — | In-app, FCM, email, WhatsApp |
| **Settings** | `/v1/settings/*`, `/uploads` | — | Bisnis, outlet, user, integrasi |
| **Platform** | `/v1/platform/*` | super-admin | Tenant, paket, billing, APK |
| **Mobile** | `/v1/mobile/*` | — | Cek versi, unduh APK |
| **Tenant** | (models) | — | `Tenant`, `Outlet`, `TenantSetting` |

### Inventori — endpoint stok

| Method | Path | Keterangan |
|--------|------|------------|
| `GET` | `/inventory/stocks` | Daftar stok per gudang |
| `GET` | `/inventory/stocks/alerts` | Alert stok menipis |
| `GET` | `/inventory/stocks/movements` | Riwayat pergerakan |
| `GET` | `/inventory/stocks/warehouses` | Daftar gudang aktif |
| `POST` | `/inventory/stocks/in` | Stok masuk |
| `POST` | `/inventory/stocks/out` | Stok keluar |
| `POST` | `/inventory/stocks/adjustment` | Sesuaikan ke jumlah baru |
| `POST` | `/inventory/stocks/import` | Import massal CSV/Excel |

Permission import: `inventory.stock.adjust`

Format import stok — template: [`templates/stock-import.csv`](./templates/stock-import.csv)

| Kolom | Wajib | Keterangan |
|-------|-------|------------|
| `sku` | Ya | SKU produk yang sudah ada |
| `quantity` | Ya | Jumlah (in/out) atau stok baru (adjustment) |
| `action` | Ya | `in`, `out`, atau `adjustment` |
| `notes` | Tidak | Catatan pergerakan |
| `warehouse_code` | Tidak | Kode gudang; kosong = gudang default |

---

## Matriks Web vs Mobile

| Modul / Fitur | Web | Mobile | Catatan |
|---------------|:---:|:------:|---------|
| Daftar tenant (`/register`) | ✅ | ❌ | Web only |
| Dashboard | ✅ | ✅ | |
| POS kasir | ✅ | ✅ | Mobile: offline + printer + kamera |
| Riwayat / void transaksi | ✅ | ✅ | |
| Shift & hold bill | ✅ | ✅ | |
| Inventori produk | ✅ | ✅ | |
| Inventori bahan baku | ✅ | ❌ | Tab web only |
| Resep / COGS | ✅ | ❌ | Tab web only |
| Import stok massal | ✅ | ❌ | Web: Inventori → Import Stok |
| Import produk massal | ✅ | ❌ | Web: Inventori → Import Produk |
| Kitchen KDS | ✅ | ❌ | `/kitchen` web only |
| QR Menu tamu | ✅ | ❌ | Halaman publik web |
| QR Menu staff | Pengaturan | ✅ | Tab di hub Member |
| Reservasi | ✅ | ✅ | Web punya kalender |
| Setup reservasi (slot) | ✅ | ❌ | Pengaturan web |
| Delivery operasional | ✅ | ✅ | Web kanban; mobile list + peta |
| Setup delivery (zona/driver) | ✅ | ❌ | Panel web |
| Member & loyalty | ✅ | ✅ | |
| Wallet penuh | ✅ | partial | Web: withdraw/transfer |
| CRM | ✅ | ✅ | |
| Laporan & export | ✅ | ❌ | Web only |
| Notifikasi | ✅ | ✅ | Mobile + FCM push |
| Pengaturan lengkap | ✅ | partial | Web: user, billing, integrasi |
| Platform super admin | ✅ | ❌ | |
| Mode standalone | ❌ | ✅ | Mobile only |
| Printer Bluetooth | ❌ | ✅ | |
| Biometrik | ❌ | ✅ | |
| Update APK OTA | ❌ | ✅ | |

---

## Celah Paritas (Gap)

### Hanya di Web

- Landing & registrasi tenant
- Panel Platform (`/platform`)
- Kitchen Display System
- Laporan bisnis + export
- Bahan baku & resep/COGS
- Setup delivery (zona, driver) & reservasi (slot, meja)
- Import stok massal & onboarding wizard
- Integrasi email/WhatsApp penuh di pengaturan
- QR Menu halaman tamu

### Hanya di Mobile

- Mode standalone (toko tanpa server)
- Konfigurasi URL server
- Printer Bluetooth & template struk
- Login biometrik
- Push FCM
- Scanner barcode/QR native
- Layar sync offline terdedikasi
- Peta/GPS driver

---

## Skrip & Template Terkait

| File | Fungsi |
|------|--------|
| `backend/scripts/import-products-csv.php` | Import produk baru dari CSV |
| `backend/scripts/import-stock-csv.php` | Import pergerakan stok dari CSV (CLI) |
| `docs/templates/products-import.csv` | Template import produk |
| `docs/templates/stock-import.csv` | Template import stok |

### Import stok via web

1. Login → **Inventori** → **Import Stok**
2. Unduh template, isi di Excel
3. Upload file `.csv` atau `.xlsx`
4. Pilih gudang default (opsional)
5. Klik **Import Stok** — lihat ringkasan berhasil/dilewati

### Import stok via CLI (server)

```bash
docker compose -f docker-compose.client.yml exec -T backend \
  php scripts/import-stock-csv.php /var/www/html/storage/app/import/stock.csv 1
```

---

## Referensi Route Web (ringkas)

| Route | Label menu |
|-------|------------|
| `/dashboard` | Dashboard |
| `/pos` | POS |
| `/pos/history` | Riwayat |
| `/kitchen` | Dapur |
| `/reservations` | Reservasi |
| `/delivery` | Delivery |
| `/inventory` | Inventori |
| `/members` | Member |
| `/crm` | CRM |
| `/reports` | Laporan |
| `/settings` | Pengaturan |
| `/platform` | Platform |

---

*Terakhir diperbarui: Juli 2026 — Creative Network*