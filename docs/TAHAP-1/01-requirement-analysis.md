# TAHAP 1 — Requirement Analysis

## CreativePOS by Creative Network

**Versi Dokumen:** 1.0  
**Tanggal:** 25 Juni 2026  
**Status:** Draft — Tahap 1

---

## 1. Executive Summary

CreativePOS adalah platform SaaS multi-tenant yang mengintegrasikan Point of Sale (POS), manajemen inventori, loyalitas member, reservasi, delivery, CRM, dan laporan bisnis dalam satu ekosistem terpadu. Sistem dirancang untuk skala enterprise dengan isolasi data per tenant, paket langganan berjenjang, dan arsitektur event-driven.

### 1.1 Problem Statement

Bisnis F&B dan retail di Indonesia menghadapi fragmentasi sistem:

- POS terpisah dari inventori
- Member loyalty manual atau terpisah
- Reservasi & delivery tidak terintegrasi
- Laporan tidak real-time
- Multi-outlet sulit dikelola
- Tidak ada isolasi data antar bisnis (untuk SaaS)

### 1.2 Solution

CreativePOS menyediakan platform terpadu dengan:

- Multi-tenant architecture (`tenant_id` pada seluruh tabel utama)
- Real-time dashboard & kitchen display via WebSocket
- QR Digital Menu untuk self-ordering
- Member wallet & loyalty terintegrasi
- CRM & WhatsApp notification
- Subscription billing untuk model SaaS

---

## 2. Stakeholder Analysis

| Stakeholder | Peran | Kebutuhan Utama |
|-------------|-------|-----------------|
| **Super Admin** | Platform operator | Kelola tenant, billing, paket, monitoring |
| **Owner** | Pemilik bisnis | Dashboard, laporan, multi-outlet, profit/loss |
| **Manager** | Manajer outlet | Operasional harian, stok, staff |
| **Supervisor** | Pengawas shift | POS oversight, void approval, shift report |
| **Cashier** | Kasir | Transaksi cepat, pembayaran, receipt |
| **Waiter** | Pelayan | Order meja, split bill, status pesanan |
| **Kitchen** | Dapur | Kitchen Display System (KDS) real-time |
| **Driver** | Kurir | Delivery assignment, GPS tracking |
| **Customer Service** | CS/CRM | Ticketing, SLA, knowledge base |
| **Customer** | Pelanggan | QR menu, member, wallet, reservasi |

---

## 3. Functional Requirements

### 3.1 Multi-Tenancy

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-MT-01 | Setiap tenant memiliki data terisolasi via `tenant_id` | Critical |
| FR-MT-02 | Tenant dapat memiliki multiple outlet | Critical |
| FR-MT-03 | User hanya dapat mengakses tenant yang di-assign | Critical |
| FR-MT-04 | Super Admin dapat mengakses semua tenant (platform level) | Critical |
| FR-MT-05 | Fitur dibatasi berdasarkan paket langganan | High |
| FR-MT-06 | Tenant dapat di-suspend/activate oleh Super Admin | High |

### 3.2 Authentication & Authorization

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-AUTH-01 | Login dengan email/password | Critical |
| FR-AUTH-02 | Register tenant baru (onboarding) | Critical |
| FR-AUTH-03 | Forgot & reset password | Critical |
| FR-AUTH-04 | Email verification | High |
| FR-AUTH-05 | OTP verification (email/SMS) | High |
| FR-AUTH-06 | WhatsApp OTP | High |
| FR-AUTH-07 | Google OAuth login | Medium |
| FR-AUTH-08 | Two Factor Authentication (2FA) | High |
| FR-AUTH-09 | Session management & device tracking | High |
| FR-AUTH-10 | Role-based access control (Spatie Permission) | Critical |

### 3.3 Point of Sale

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-POS-01 | Quick sale dengan barcode/QR scanner | Critical |
| FR-POS-02 | Hold & resume transaction | High |
| FR-POS-03 | Split bill & merge bill | High |
| FR-POS-04 | Refund, return, void transaction | Critical |
| FR-POS-05 | Multi payment method (Cash, Transfer, QRIS, Card, E-Wallet) | Critical |
| FR-POS-06 | Diskon (%, nominal, voucher, promo) | High |
| FR-POS-07 | Thermal printer 58mm & 80mm | High |
| FR-POS-08 | Reprint receipt | Medium |

### 3.4 Inventory

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-INV-01 | Product management (category, variant, bundle) | Critical |
| FR-INV-02 | Stock in/out/transfer/adjustment/opname | Critical |
| FR-INV-03 | Multi warehouse & multi outlet inventory | High |
| FR-INV-04 | Supplier & purchase order management | High |
| FR-INV-05 | Goods receipt & purchase return | High |
| FR-INV-06 | Low stock alert | High |

### 3.5 Loyalty & Member Wallet

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-LOY-01 | Member registration dengan QR/barcode | High |
| FR-LOY-02 | Configurable point system | High |
| FR-LOY-03 | Membership tier (Bronze–Platinum) | High |
| FR-LOY-04 | Reward (voucher, cashback, product, birthday, referral) | Medium |
| FR-WAL-01 | Wallet balance, top-up, withdraw, transfer | High |
| FR-WAL-02 | Wallet payment di POS | High |

### 3.6 QR Digital Menu

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-QR-01 | Scan QR meja untuk akses menu | High |
| FR-QR-02 | Browse menu dengan foto & availability | High |
| FR-QR-03 | Cart & checkout tanpa login (guest) atau dengan member | High |
| FR-QR-04 | Order masuk ke kitchen display & POS | Critical |

### 3.7 Kitchen Display System

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-KDS-01 | Real-time order display via WebSocket | Critical |
| FR-KDS-02 | Status flow: Pending → Cooking → Ready → Served | Critical |
| FR-KDS-03 | Filter by station/category | Medium |

### 3.8 Reservation

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-RES-01 | Table reservation dengan guest count & time slot | High |
| FR-RES-02 | Status management (Pending → Confirmed → Arrived → Completed) | High |
| FR-RES-03 | Reminder via WhatsApp & email | Medium |

### 3.9 Delivery

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-DEL-01 | Delivery order dengan status tracking | High |
| FR-DEL-02 | Internal & external driver assignment | High |
| FR-DEL-03 | Multiple address & GPS coordinate | High |
| FR-DEL-04 | Shipping fee (flat & distance-based) | High |
| FR-DEL-05 | Maps integration (Google Maps / OSM) | Medium |

### 3.10 CRM (Customer Service)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-CRM-01 | Ticketing system dengan SLA | High |
| FR-CRM-02 | Multi-channel (WhatsApp, Telegram, Email, Website) | High |
| FR-CRM-03 | Knowledge base (FAQ, docs, tutorials) | Medium |
| FR-CRM-04 | Customer rating 1–5 | Medium |

### 3.11 WhatsApp Integration

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-WA-01 | OTP via WhatsApp | High |
| FR-WA-02 | Invoice & payment notification | High |
| FR-WA-03 | Reservation reminder | Medium |
| FR-WA-04 | Loyalty & promo broadcast | Medium |

### 3.12 Reporting

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-RPT-01 | Sales report (daily/weekly/monthly/yearly) | Critical |
| FR-RPT-02 | Product sales, customer activity, member growth | High |
| FR-RPT-03 | Inventory movement, purchase, profit/loss, cash flow | High |
| FR-RPT-04 | Export PDF, Excel, CSV | High |

### 3.13 SaaS Billing (Super Admin)

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-SAAS-01 | Tenant CRUD & suspend/activate | Critical |
| FR-SAAS-02 | Package management (Starter/Business/Professional/Enterprise) | Critical |
| FR-SAAS-03 | Subscription & billing management | Critical |
| FR-SAAS-04 | Feature gating per package | High |

### 3.14 Dashboard

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-DSH-01 | Real-time KPI (revenue, best seller, outlet performance) | Critical |
| FR-DSH-02 | Charts (sales, customer growth, product performance) | High |
| FR-DSH-03 | Alerts (stock, open tickets, active reservations/deliveries) | High |

---

## 4. Non-Functional Requirements

### 4.1 Performance

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-PERF-01 | API response time (95th percentile) | < 200ms |
| NFR-PERF-02 | POS transaction completion | < 3 detik |
| NFR-PERF-03 | WebSocket latency (KDS) | < 500ms |
| NFR-PERF-04 | Dashboard load time | < 2 detik |
| NFR-PERF-05 | Concurrent users per tenant | 50+ |
| NFR-PERF-06 | Report generation (monthly) | < 30 detik |

### 4.2 Scalability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-SCALE-01 | Horizontal scaling via Docker | Yes |
| NFR-SCALE-02 | Queue worker untuk async jobs | Redis + Horizon |
| NFR-SCALE-03 | Database indexing strategy | Per tenant_id + foreign keys |
| NFR-SCALE-04 | CDN untuk static assets | Optional |

### 4.3 Security

| ID | Requirement |
|----|-------------|
| NFR-SEC-01 | CSRF protection (Laravel default + Sanctum) |
| NFR-SEC-02 | XSS protection (input sanitization, CSP headers) |
| NFR-SEC-03 | SQL injection protection (Eloquent ORM, prepared statements) |
| NFR-SEC-04 | Rate limiting (login, API, OTP) |
| NFR-SEC-05 | Audit log & activity log |
| NFR-SEC-06 | Login history & device tracking |
| NFR-SEC-07 | Tenant data isolation (global scope + policy) |
| NFR-SEC-08 | Encryption at rest (sensitive fields) |
| NFR-SEC-09 | HTTPS only in production |
| NFR-SEC-10 | 2FA support (TOTP) |

### 4.4 Availability & Reliability

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-AVAIL-01 | Uptime SLA | 99.9% |
| NFR-AVAIL-02 | Database backup | Daily automated |
| NFR-AVAIL-03 | Disaster recovery RPO | < 1 jam |
| NFR-AVAIL-04 | Disaster recovery RTO | < 4 jam |

### 4.5 Usability

| ID | Requirement |
|----|-------------|
| NFR-UX-01 | Responsive design (desktop, tablet, mobile PWA) |
| NFR-UX-02 | POS optimized for touch screen |
| NFR-UX-03 | Keyboard shortcuts for cashier |
| NFR-UX-04 | Dark mode support |
| NFR-UX-05 | Bahasa Indonesia sebagai default |

### 4.6 Compliance

| ID | Requirement |
|----|-------------|
| NFR-COMP-01 | GDPR-ready data export & deletion |
| NFR-COMP-02 | PCI-DSS awareness untuk payment card data |
| NFR-COMP-03 | Audit trail untuk transaksi finansial |

---

## 5. System Constraints

| Constraint | Detail |
|------------|--------|
| Backend | Laravel 12, PHP 8.4 |
| Database | MySQL 8 |
| Cache/Queue | Redis |
| Frontend | Next.js 15, TypeScript |
| Auth | Laravel Sanctum (SPA + API tokens) |
| Permission | Spatie Laravel Permission |
| Real-time | Laravel WebSocket (Reverb/Pusher compatible) |
| Deployment | Docker Compose on Ubuntu Server |
| Multi-tenant | Shared database, `tenant_id` column strategy |

---

## 6. Assumptions

1. Setiap tenant memiliki domain/subdomain atau slug unik (`tenant.creativepos.app` atau `creativepos.app/t/{slug}`)
2. Payment gateway (QRIS, E-Wallet) diintegrasikan via third-party API (Midtrans/Xendit)
3. WhatsApp menggunakan Business API (Meta Cloud API atau provider pihak ketiga)
4. Thermal printer menggunakan ESC/POS protocol via browser print atau local agent
5. Maps menggunakan Google Maps API atau OpenStreetMap (Leaflet)
6. Email dikirim via SMTP atau transactional email service (Mailgun/SES)
7. File storage menggunakan local/S3-compatible storage
8. Timezone default: Asia/Jakarta (WIB), configurable per tenant

---

## 7. Out of Scope (Phase 1)

| Item | Reason |
|------|--------|
| Native iOS/Android app | PWA sebagai mobile strategy |
| Accounting integration (Jurnal, Accurate) | Future phase |
| Marketplace integration (GoFood, GrabFood) | Future phase |
| Hardware POS terminal proprietary | Generic ESC/POS support |
| Multi-currency | IDR only in Phase 1 |
| Multi-language UI | ID + EN in future |

---

## 8. Success Criteria

| Metric | Target |
|--------|--------|
| Tenant onboarding | < 10 menit |
| POS transaction speed | < 3 detik end-to-end |
| Data isolation | 0 cross-tenant data leak |
| Uptime | 99.9% |
| User satisfaction (CSAT) | ≥ 4.0/5.0 |
| Module coverage | 100% modul sesuai spec |

---

## 9. Glossary

| Term | Definition |
|------|------------|
| **Tenant** | Organisasi/bisnis yang berlangganan CreativePOS |
| **Outlet** | Cabang/lokasi fisik dalam satu tenant |
| **Warehouse** | Gudang penyimpanan stok |
| **SKU** | Stock Keeping Unit — kode unik produk |
| **KDS** | Kitchen Display System |
| **SLA** | Service Level Agreement untuk ticketing |
| **Opname** | Stock opname / physical inventory count |
| **Void** | Pembatalan transaksi sebelum settlement |
| **Refund** | Pengembalian dana setelah settlement |
| **QRIS** | Quick Response Code Indonesian Standard |
| **PWA** | Progressive Web App |