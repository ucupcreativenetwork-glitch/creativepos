# TAHAP 2 — Data Dictionary: Platform & Auth

---

## PLATFORM TABLES

### `tenants`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| uuid | CHAR(36) | NO | UK | — | Public identifier (UUID v4) |
| name | VARCHAR(255) | NO | | — | Nama bisnis |
| slug | VARCHAR(100) | NO | UK | — | URL slug unik (e.g. `warung-makan`) |
| email | VARCHAR(255) | NO | UK | — | Email owner/tenant |
| phone | VARCHAR(20) | YES | | NULL | Nomor telepon |
| logo_url | VARCHAR(500) | YES | | NULL | URL logo bisnis |
| address | TEXT | YES | | NULL | Alamat bisnis |
| npwp | VARCHAR(30) | YES | | NULL | NPWP bisnis |
| status | ENUM | NO | IDX | 'trial' | `active`, `suspended`, `trial`, `terminated` |
| trial_ends_at | TIMESTAMP | YES | | NULL | Akhir masa trial |
| suspended_at | TIMESTAMP | YES | | NULL | Waktu suspend |
| terminated_at | TIMESTAMP | YES | | NULL | Waktu terminate |
| timezone | VARCHAR(50) | NO | | 'Asia/Jakarta' | Zona waktu |
| currency | VARCHAR(3) | NO | | 'IDR' | Mata uang |
| locale | VARCHAR(10) | NO | | 'id' | Locale |
| created_at | TIMESTAMP | NO | | CURRENT | Waktu dibuat |
| updated_at | TIMESTAMP | NO | | CURRENT | Waktu diupdate |
| deleted_at | TIMESTAMP | YES | | NULL | Soft delete |

### `packages`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| name | VARCHAR(100) | NO | | — | Nama paket (Starter, Business, dll) |
| slug | VARCHAR(50) | NO | UK | — | Slug paket |
| description | TEXT | YES | | NULL | Deskripsi paket |
| price_monthly | DECIMAL(15,2) | NO | | 0 | Harga bulanan (IDR) |
| price_yearly | DECIMAL(15,2) | NO | | 0 | Harga tahunan (IDR) |
| max_outlets | INT | NO | | 1 | Maks outlet |
| max_users | INT | NO | | 5 | Maks user |
| max_products | INT | NO | | 100 | Maks produk |
| max_members | INT | NO | | 500 | Maks member |
| wa_quota_monthly | INT | NO | | 0 | Kuota WA/bulan |
| trial_days | INT | NO | | 14 | Hari trial |
| sort_order | INT | NO | | 0 | Urutan tampilan |
| is_active | TINYINT(1) | NO | | 1 | Status aktif |

### `package_features`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| package_id | BIGINT UNSIGNED | NO | FK | — | → packages.id |
| feature_key | VARCHAR(100) | NO | UK* | — | Key fitur (e.g. `pos`, `delivery`, `crm`) |
| feature_value | VARCHAR(255) | YES | | NULL | Nilai fitur (e.g. max 3 outlets) |
| is_enabled | TINYINT(1) | NO | | 1 | Enabled/disabled |

*UK = unique with package_id

### `subscriptions`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| package_id | BIGINT UNSIGNED | NO | FK | — | → packages.id |
| status | ENUM | NO | IDX | 'active' | `active`, `past_due`, `suspended`, `cancelled`, `expired` |
| billing_cycle | ENUM | NO | | 'monthly' | `monthly`, `yearly` |
| starts_at | DATE | NO | | — | Tanggal mulai |
| ends_at | DATE | NO | | — | Tanggal berakhir |
| next_billing_date | DATE | YES | IDX | NULL | Tanggal billing berikutnya |
| cancelled_at | TIMESTAMP | YES | | NULL | Waktu cancel |

### `billing_invoices`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| subscription_id | BIGINT UNSIGNED | NO | FK | — | → subscriptions.id |
| invoice_number | VARCHAR(50) | NO | UK | — | Nomor invoice (INV-2026-00001) |
| amount | DECIMAL(15,2) | NO | | — | Subtotal |
| tax_amount | DECIMAL(15,2) | NO | | 0 | Pajak |
| total_amount | DECIMAL(15,2) | NO | | — | Total |
| status | ENUM | NO | IDX | 'draft' | `draft`, `sent`, `paid`, `overdue`, `cancelled` |
| due_date | DATE | NO | | — | Jatuh tempo |
| paid_at | TIMESTAMP | YES | | NULL | Waktu bayar |
| period_start | DATE | NO | | — | Awal periode |
| period_end | DATE | NO | | — | Akhir periode |

### `billing_payments`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| invoice_id | BIGINT UNSIGNED | NO | FK | — | → billing_invoices.id |
| tenant_id | BIGINT UNSIGNED | NO | FK | — | → tenants.id |
| amount | DECIMAL(15,2) | NO | | — | Jumlah bayar |
| payment_method | VARCHAR(50) | NO | | — | Metode (transfer, qris, dll) |
| transaction_ref | VARCHAR(255) | YES | | NULL | Referensi gateway |
| gateway_response | JSON | YES | | NULL | Response payment gateway |
| paid_at | TIMESTAMP | NO | | — | Waktu pembayaran |

---

## AUTH TABLES

### `users`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → tenants.id (NULL for super admin) |
| uuid | CHAR(36) | NO | UK | — | Public identifier |
| name | VARCHAR(255) | NO | | — | Nama lengkap |
| email | VARCHAR(255) | NO | UK* | — | Email login |
| phone | VARCHAR(20) | YES | | NULL | Nomor telepon |
| password | VARCHAR(255) | NO | | — | Bcrypt hash |
| avatar_url | VARCHAR(500) | YES | | NULL | Foto profil |
| outlet_id | BIGINT UNSIGNED | YES | FK | NULL | → outlets.id (default outlet) |
| is_super_admin | TINYINT(1) | NO | | 0 | Flag super admin platform |
| status | ENUM | NO | IDX | 'active' | `active`, `inactive`, `suspended` |
| email_verified_at | TIMESTAMP | YES | | NULL | Waktu verifikasi email |
| two_factor_enabled | TINYINT(1) | NO | | 0 | 2FA aktif |
| two_factor_secret | TEXT | YES | | NULL | TOTP secret (encrypted) |
| two_factor_method | ENUM | YES | | NULL | `totp`, `whatsapp`, `email` |
| last_login_at | TIMESTAMP | YES | | NULL | Login terakhir |
| last_login_ip | VARCHAR(45) | YES | | NULL | IP login terakhir |

*UK = unique with tenant_id

### `otp_verifications`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | YES | IDX | NULL | → tenants.id |
| identifier | VARCHAR(255) | NO | IDX | — | Email atau phone |
| channel | ENUM | NO | | — | `email`, `whatsapp`, `sms` |
| code_hash | VARCHAR(255) | NO | | — | Bcrypt hash OTP |
| purpose | ENUM | NO | | — | `login`, `register`, `reset_password`, `verify_phone`, `transaction` |
| attempts | INT | NO | | 0 | Percobaan verifikasi |
| max_attempts | INT | NO | | 5 | Maks percobaan |
| expires_at | TIMESTAMP | NO | | — | Kadaluarsa (5 menit) |
| verified_at | TIMESTAMP | YES | | NULL | Waktu terverifikasi |

### `login_histories`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| user_id | BIGINT UNSIGNED | NO | FK, IDX | — | → users.id |
| tenant_id | BIGINT UNSIGNED | YES | IDX | NULL | → tenants.id |
| ip_address | VARCHAR(45) | NO | | — | IP address |
| user_agent | TEXT | YES | | NULL | Browser user agent |
| device_fingerprint | VARCHAR(255) | YES | | NULL | Device fingerprint |
| device_name | VARCHAR(255) | YES | | NULL | Nama device |
| location | VARCHAR(255) | YES | | NULL | Geo location |
| is_successful | TINYINT(1) | NO | | 1 | Login berhasil |
| failure_reason | VARCHAR(255) | YES | | NULL | Alasan gagal |
| logged_in_at | TIMESTAMP | NO | IDX | CURRENT | Waktu login |
| logged_out_at | TIMESTAMP | YES | | NULL | Waktu logout |

### `user_devices`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| user_id | BIGINT UNSIGNED | NO | FK | — | → users.id |
| device_name | VARCHAR(255) | NO | | — | Nama device |
| fingerprint | VARCHAR(255) | NO | UK* | — | Unique fingerprint |
| platform | VARCHAR(50) | YES | | NULL | OS platform |
| browser | VARCHAR(100) | YES | | NULL | Browser name |
| is_trusted | TINYINT(1) | NO | | 0 | Device terpercaya |
| last_used_at | TIMESTAMP | YES | | NULL | Terakhir digunakan |

### `roles` (Spatie)

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | YES | IDX | NULL | → tenants.id (NULL = system role) |
| name | VARCHAR(255) | NO | UK* | — | Nama role (owner, cashier, dll) |
| guard_name | VARCHAR(255) | NO | | 'web' | Guard name |
| is_system | TINYINT(1) | NO | | 0 | Role bawaan sistem |

**System Roles:** super-admin, owner, manager, supervisor, cashier, waiter, kitchen, driver, customer-service, customer

### `permissions` (Spatie)

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| name | VARCHAR(255) | NO | UK* | — | Nama permission (e.g. `pos.create`) |
| guard_name | VARCHAR(255) | NO | | 'web' | Guard name |
| module | VARCHAR(50) | YES | | NULL | Modul (pos, inventory, dll) |
| description | VARCHAR(255) | YES | | NULL | Deskripsi permission |

---

## TENANT CONFIG TABLES

### `tenant_settings`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, UK | — | → tenants.id |
| business_name | VARCHAR(255) | YES | | NULL | Nama tampilan bisnis |
| business_type | ENUM | YES | | NULL | Jenis bisnis |
| logo_url | VARCHAR(500) | YES | | NULL | Logo |
| primary_color | VARCHAR(7) | YES | | '#2563EB' | Warna utama (hex) |
| service_charge_rate | DECIMAL(5,2) | NO | | 0 | % service charge |
| tax_rate | DECIMAL(5,2) | NO | | 11.00 | % PPN |
| setup_completed | TINYINT(1) | NO | | 0 | Setup wizard selesai |

### `outlets`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | UK | — | Public identifier |
| name | VARCHAR(255) | NO | | — | Nama outlet |
| code | VARCHAR(20) | NO | UK* | — | Kode outlet (e.g. OUT01) |
| address | TEXT | YES | | NULL | Alamat |
| latitude | DECIMAL(10,8) | YES | | NULL | GPS latitude |
| longitude | DECIMAL(11,8) | YES | | NULL | GPS longitude |
| is_active | TINYINT(1) | NO | | 1 | Status aktif |
| is_default | TINYINT(1) | NO | | 0 | Outlet default |

### `integration_settings`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, UK* | — | → tenants.id |
| provider | ENUM | NO | | — | `midtrans`, `xendit`, `whatsapp`, `google_maps`, `osm`, `mailgun`, `ses` |
| config | JSON | NO | | — | API keys & config (encrypted) |
| is_active | TINYINT(1) | NO | | 0 | Status aktif |

*UK = unique with tenant_id + provider