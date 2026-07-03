# TAHAP 2 — Data Dictionary: CRM, WhatsApp, Audit & Finance

---

## CRM TABLES

### `support_tickets`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | | — | Public identifier |
| ticket_number | VARCHAR(50) | NO | UK* | — | Nomor tiket (TKT-2026-00001) |
| member_id | BIGINT UNSIGNED | YES | FK | NULL | → members.id |
| customer_name | VARCHAR(255) | YES | | NULL | Nama customer (non-member) |
| customer_email | VARCHAR(255) | YES | | NULL | Email customer |
| customer_phone | VARCHAR(20) | YES | | NULL | Telepon customer |
| channel | ENUM | NO | | — | `whatsapp`, `telegram`, `email`, `website`, `phone` |
| subject | VARCHAR(255) | NO | | — | Subjek tiket |
| priority | ENUM | NO | IDX | 'medium' | `low`, `medium`, `high`, `critical` |
| status | ENUM | NO | IDX | 'open' | `open`, `assigned`, `pending`, `resolved`, `closed` |
| assigned_to | BIGINT UNSIGNED | YES | FK, IDX | NULL | → users.id (CS agent) |
| sla_deadline | TIMESTAMP | YES | | NULL | Deadline SLA |
| first_response_at | TIMESTAMP | YES | | NULL | First response time |
| resolved_at | TIMESTAMP | YES | | NULL | Waktu resolved |
| closed_at | TIMESTAMP | YES | | NULL | Waktu closed |

### `ticket_messages`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| ticket_id | BIGINT UNSIGNED | NO | FK, IDX | — | → support_tickets.id |
| sender_type | ENUM | NO | | — | `customer`, `agent`, `system` |
| sender_id | BIGINT UNSIGNED | YES | | NULL | → users.id or members.id |
| message | TEXT | NO | | — | Isi pesan |
| attachments | JSON | YES | | NULL | File attachments |
| is_internal | TINYINT(1) | NO | | 0 | Catatan internal (tidak ke customer) |

### `sla_policies`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, UK* | — | → tenants.id |
| priority | ENUM | NO | | — | `low`, `medium`, `high`, `critical` |
| first_response_minutes | INT | NO | | — | SLA first response (menit) |
| resolution_minutes | INT | NO | | — | SLA resolution (menit) |

**Default SLA:**

| Priority | First Response | Resolution |
|----------|---------------|------------|
| critical | 15 min | 120 min |
| high | 30 min | 240 min |
| medium | 120 min | 1440 min |
| low | 240 min | 2880 min |

### `knowledge_base_articles`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| category_id | BIGINT UNSIGNED | NO | FK | — | → knowledge_base_categories.id |
| title | VARCHAR(255) | NO | FT | — | Judul artikel |
| slug | VARCHAR(255) | NO | | — | URL slug |
| content | LONGTEXT | NO | FT | — | Isi artikel (HTML/Markdown) |
| is_published | TINYINT(1) | NO | | 0 | Status publish |
| view_count | INT | NO | | 0 | Jumlah view |

### `csat_surveys`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| ticket_id | BIGINT UNSIGNED | YES | FK | NULL | → support_tickets.id |
| delivery_order_id | BIGINT UNSIGNED | YES | FK | NULL | → delivery_orders.id |
| rating | TINYINT | NO | | — | 1-5 bintang |
| comment | TEXT | YES | | NULL | Komentar |

---

## WHATSAPP TABLES

### `whatsapp_configs`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, UK | — | → tenants.id |
| provider | VARCHAR(50) | NO | | — | Provider WA API |
| phone_number_id | VARCHAR(100) | YES | | NULL | WA phone number ID |
| access_token | TEXT | YES | | NULL | Access token (encrypted) |
| webhook_verify_token | VARCHAR(255) | YES | | NULL | Webhook verify token |
| monthly_quota | INT | NO | | 0 | Kuota bulanan |
| used_quota | INT | NO | | 0 | Kuota terpakai |
| is_active | TINYINT(1) | NO | | 0 | Status aktif |

### `whatsapp_templates`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| name | VARCHAR(100) | NO | | — | Nama template |
| template_id | VARCHAR(100) | YES | | NULL | ID template di WA API |
| category | ENUM | NO | | — | `otp`, `invoice`, `reminder`, `loyalty`, `promo`, `delivery`, `custom` |
| content | TEXT | NO | | — | Isi template |
| variables | JSON | YES | | NULL | Variabel template `["name","amount"]` |
| status | ENUM | NO | | 'pending' | `pending`, `approved`, `rejected` |

### `whatsapp_messages`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| template_id | BIGINT UNSIGNED | YES | FK | NULL | → whatsapp_templates.id |
| recipient_phone | VARCHAR(20) | NO | | — | Nomor penerima |
| message | TEXT | NO | | — | Isi pesan |
| status | ENUM | NO | IDX | 'queued' | `queued`, `sent`, `delivered`, `read`, `failed` |
| external_id | VARCHAR(255) | YES | | NULL | ID dari WA API |
| error_message | TEXT | YES | | NULL | Pesan error |
| sent_at | TIMESTAMP | YES | | NULL | Waktu terkirim |

### `whatsapp_broadcasts`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| template_id | BIGINT UNSIGNED | NO | FK | — | → whatsapp_templates.id |
| name | VARCHAR(255) | NO | | — | Nama broadcast |
| status | ENUM | NO | | 'draft' | `draft`, `scheduled`, `sending`, `completed`, `cancelled` |
| scheduled_at | TIMESTAMP | YES | | NULL | Waktu jadwal |
| total_recipients | INT | NO | | 0 | Total penerima |
| sent_count | INT | NO | | 0 | Terkirim |
| failed_count | INT | NO | | 0 | Gagal |

---

## AUDIT & SECURITY TABLES

### `audit_logs`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → tenants.id |
| user_id | BIGINT UNSIGNED | YES | FK | NULL | → users.id |
| event | ENUM | NO | | — | `created`, `updated`, `deleted`, `restored` |
| auditable_type | VARCHAR(255) | NO | IDX | — | Model class name |
| auditable_id | BIGINT UNSIGNED | NO | | — | Model ID |
| old_values | JSON | YES | | NULL | Nilai sebelum perubahan |
| new_values | JSON | YES | | NULL | Nilai setelah perubahan |
| ip_address | VARCHAR(45) | YES | | NULL | IP address |
| user_agent | TEXT | YES | | NULL | User agent |
| created_at | TIMESTAMP | NO | IDX | CURRENT | Waktu event |

### `activity_logs`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → tenants.id |
| user_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → users.id |
| action | VARCHAR(100) | NO | | — | Aksi (login, export, void, dll) |
| description | TEXT | YES | | NULL | Deskripsi aksi |
| properties | JSON | YES | | NULL | Data tambahan |
| ip_address | VARCHAR(45) | YES | | NULL | IP address |
| created_at | TIMESTAMP | NO | IDX | CURRENT | Waktu aksi |

### `security_events`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → tenants.id |
| user_id | BIGINT UNSIGNED | YES | FK | NULL | → users.id |
| event_type | ENUM | NO | IDX | — | `failed_login`, `account_locked`, `password_changed`, `2fa_enabled`, `2fa_disabled`, `suspicious_activity`, `ip_blocked` |
| ip_address | VARCHAR(45) | YES | | NULL | IP address |
| details | JSON | YES | | NULL | Detail event |
| created_at | TIMESTAMP | NO | | CURRENT | Waktu event |

---

## REPORTING TABLES

### `scheduled_reports`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| report_type | VARCHAR(100) | NO | | — | Tipe laporan (sales_daily, pnl, dll) |
| frequency | ENUM | NO | | — | `daily`, `weekly`, `monthly` |
| format | ENUM | NO | | 'pdf' | `pdf`, `excel`, `csv` |
| recipients | JSON | NO | | — | Email recipients array |
| filters | JSON | YES | | NULL | Filter (outlet, date range) |
| next_run_at | TIMESTAMP | NO | | — | Jadwal berikutnya |
| last_run_at | TIMESTAMP | YES | | NULL | Terakhir dijalankan |
| is_active | TINYINT(1) | NO | | 1 | Status aktif |

### `report_exports`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| report_type | VARCHAR(100) | NO | | — | Tipe laporan |
| format | ENUM | NO | | — | `pdf`, `excel`, `csv` |
| file_path | VARCHAR(500) | NO | | — | Path file export |
| file_size | BIGINT | YES | | NULL | Ukuran file (bytes) |
| filters | JSON | YES | | NULL | Filter yang digunakan |
| generated_by | BIGINT UNSIGNED | YES | FK | NULL | → users.id |

### `report_snapshots`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| outlet_id | BIGINT UNSIGNED | YES | FK | NULL | → outlets.id |
| snapshot_date | DATE | NO | IDX | — | Tanggal snapshot |
| report_type | VARCHAR(100) | NO | | — | Tipe laporan |
| data | JSON | NO | | — | Data snapshot (pre-computed) |

---

## FINANCE TABLES

### `expenses`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| outlet_id | BIGINT UNSIGNED | YES | FK | NULL | → outlets.id |
| category_id | BIGINT UNSIGNED | NO | FK | — | → expense_categories.id |
| amount | DECIMAL(15,2) | NO | | — | Jumlah pengeluaran |
| description | TEXT | NO | | — | Deskripsi |
| expense_date | DATE | NO | IDX | — | Tanggal pengeluaran |
| receipt_url | VARCHAR(500) | YES | | NULL | Bukti pembayaran |
| created_by | BIGINT UNSIGNED | YES | FK | NULL | → users.id |

### `chart_of_accounts`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| code | VARCHAR(20) | NO | UK* | — | Kode akun (1-1000, 4-4000) |
| name | VARCHAR(255) | NO | | — | Nama akun |
| type | ENUM | NO | | — | `asset`, `liability`, `equity`, `revenue`, `expense` |
| parent_id | BIGINT UNSIGNED | YES | FK | NULL | → chart_of_accounts.id (hierarki) |

### `journal_entries`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| entry_number | VARCHAR(50) | NO | | — | Nomor jurnal |
| entry_date | DATE | NO | | — | Tanggal jurnal |
| description | TEXT | NO | | — | Deskripsi |
| reference_type | VARCHAR(100) | YES | | NULL | Polymorphic type |
| reference_id | BIGINT UNSIGNED | YES | | NULL | Polymorphic ID |
| status | ENUM | NO | | 'draft' | `draft`, `posted`, `voided` |
| posted_at | TIMESTAMP | YES | | NULL | Waktu posting |

### `journal_entry_lines`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| journal_entry_id | BIGINT UNSIGNED | NO | FK, IDX | — | → journal_entries.id |
| account_id | BIGINT UNSIGNED | NO | FK | — | → chart_of_accounts.id |
| debit | DECIMAL(15,2) | NO | | 0 | Debit |
| credit | DECIMAL(15,2) | NO | | 0 | Credit |
| description | VARCHAR(255) | YES | | NULL | Keterangan baris |

### `cash_flow_entries`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| outlet_id | BIGINT UNSIGNED | YES | FK | NULL | → outlets.id |
| type | ENUM | NO | | — | `inflow`, `outflow` |
| category | VARCHAR(100) | NO | | — | Kategori arus kas |
| amount | DECIMAL(15,2) | NO | | — | Jumlah |
| description | TEXT | YES | | NULL | Deskripsi |
| entry_date | DATE | NO | IDX | — | Tanggal |
| reference_type | VARCHAR(100) | YES | | NULL | Polymorphic type |
| reference_id | BIGINT UNSIGNED | YES | | NULL | Polymorphic ID |

---

## NOTIFICATION TABLES

### `notifications`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| user_id | BIGINT UNSIGNED | NO | FK, IDX | — | → users.id |
| type | VARCHAR(100) | NO | | — | Tipe notifikasi |
| title | VARCHAR(255) | NO | | — | Judul |
| body | TEXT | YES | | NULL | Isi notifikasi |
| data | JSON | YES | | NULL | Data tambahan |
| read_at | TIMESTAMP | YES | IDX | NULL | Waktu dibaca |

---

## ENUM VALUES REFERENCE

### Status Enums (Global)

| Table | Column | Values |
|-------|--------|--------|
| tenants | status | active, suspended, trial, terminated |
| users | status | active, inactive, suspended |
| sale_transactions | status | pending, completed, voided, refunded, partial_refund |
| orders | status | pending, cooking, ready, served, completed, cancelled |
| reservations | status | pending, confirmed, arrived, completed, cancelled, no_show |
| delivery_orders | status | waiting, processing, cooking, ready, delivering, completed, cancelled |
| support_tickets | status | open, assigned, pending, resolved, closed |
| purchase_orders | status | draft, pending_approval, approved, ordered, partial, received, cancelled |
| subscriptions | status | active, past_due, suspended, cancelled, expired |
| billing_invoices | status | draft, sent, paid, overdue, cancelled |