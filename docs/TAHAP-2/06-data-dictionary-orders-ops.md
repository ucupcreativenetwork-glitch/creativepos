# TAHAP 2 — Data Dictionary: Orders, Loyalty, Reservation & Delivery

---

## LOYALTY & MEMBER TABLES

### `members`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | UK | — | Public identifier |
| member_code | VARCHAR(50) | NO | UK* | — | Kode member (MBR-00001) |
| name | VARCHAR(255) | NO | | — | Nama member |
| email | VARCHAR(255) | YES | | NULL | Email |
| phone | VARCHAR(20) | NO | UK* | — | Nomor telepon |
| gender | ENUM | YES | | NULL | `male`, `female`, `other` |
| birthday | DATE | YES | | NULL | Tanggal lahir |
| tier_id | BIGINT UNSIGNED | YES | FK | NULL | → tier_configs.id |
| qr_code_url | VARCHAR(500) | YES | | NULL | URL QR code |
| barcode | VARCHAR(100) | YES | | NULL | Barcode member |
| referral_code | VARCHAR(20) | YES | | NULL | Kode referral pribadi |
| referred_by | BIGINT UNSIGNED | YES | FK | NULL | → members.id |
| total_spend | DECIMAL(15,2) | NO | | 0 | Total belanja (12 bulan) |
| visit_count | INT | NO | | 0 | Jumlah kunjungan |
| last_visit_at | TIMESTAMP | YES | | NULL | Kunjungan terakhir |
| status | ENUM | NO | | 'active' | `active`, `inactive`, `blocked` |

### `tier_configs`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| name | VARCHAR(50) | NO | | — | Nama tier |
| slug | ENUM | NO | UK* | — | `bronze`, `silver`, `gold`, `platinum` |
| min_spend | DECIMAL(15,2) | NO | | 0 | Min belanja untuk tier |
| point_multiplier | DECIMAL(3,1) | NO | | 1.0 | Pengali poin (1x, 1.5x, 2x, 3x) |
| benefits | JSON | YES | | NULL | Benefit tier (JSON) |

### `point_configs`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, UK | — | → tenants.id |
| earn_amount | DECIMAL(15,2) | NO | | 10000 | Rp per poin (e.g. Rp 10.000) |
| earn_points | INT | NO | | 1 | Poin yang didapat |
| redeem_points | INT | NO | | 100 | Poin untuk redeem |
| redeem_value | DECIMAL(15,2) | NO | | 10000 | Nilai redeem (Rp) |
| point_expiry_days | INT | YES | | NULL | Hari kadaluarsa poin |
| min_redeem_points | INT | NO | | 100 | Min poin redeem |

### `member_points`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK | — | → tenants.id |
| member_id | BIGINT UNSIGNED | NO | FK, UK | — | → members.id |
| balance | INT | NO | | 0 | Saldo poin saat ini |
| lifetime_earned | INT | NO | | 0 | Total poin earned |
| lifetime_redeemed | INT | NO | | 0 | Total poin redeemed |

### `point_transactions`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| member_id | BIGINT UNSIGNED | NO | FK, IDX | — | → members.id |
| type | ENUM | NO | | — | `earn`, `redeem`, `expire`, `adjustment`, `referral`, `birthday` |
| points | INT | NO | | — | Jumlah poin (+/-) |
| balance_after | INT | NO | | — | Saldo setelah transaksi |
| reference_type | VARCHAR(100) | YES | | NULL | Polymorphic type |
| reference_id | BIGINT UNSIGNED | YES | | NULL | Polymorphic ID |
| description | VARCHAR(255) | YES | | NULL | Keterangan |
| expires_at | TIMESTAMP | YES | | NULL | Kadaluarsa poin |

---

## WALLET TABLES

### `wallets`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| member_id | BIGINT UNSIGNED | NO | FK, UK | — | → members.id |
| balance | DECIMAL(15,2) | NO | | 0 | Saldo wallet |
| lifetime_topup | DECIMAL(15,2) | NO | | 0 | Total top up |
| lifetime_spent | DECIMAL(15,2) | NO | | 0 | Total pengeluaran |
| status | ENUM | NO | | 'active' | `active`, `frozen`, `closed` |

### `wallet_transactions`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| wallet_id | BIGINT UNSIGNED | NO | FK, IDX | — | → wallets.id |
| type | ENUM | NO | | — | `topup`, `withdraw`, `transfer_in`, `transfer_out`, `payment`, `refund`, `adjustment` |
| amount | DECIMAL(15,2) | NO | | — | Jumlah |
| balance_before | DECIMAL(15,2) | NO | | — | Saldo sebelum |
| balance_after | DECIMAL(15,2) | NO | | — | Saldo sesudah |
| reference_type | VARCHAR(100) | YES | | NULL | Polymorphic type |
| reference_id | BIGINT UNSIGNED | YES | | NULL | Polymorphic ID |
| description | VARCHAR(255) | YES | | NULL | Keterangan |

---

## ORDER & KDS TABLES

### `orders`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | UK | — | Public identifier |
| order_number | VARCHAR(50) | NO | UK* | — | Nomor order |
| outlet_id | BIGINT UNSIGNED | NO | FK, IDX | — | → outlets.id |
| table_id | BIGINT UNSIGNED | YES | FK | NULL | → tables.id |
| member_id | BIGINT UNSIGNED | YES | FK | NULL | → members.id |
| sale_transaction_id | BIGINT UNSIGNED | YES | FK | NULL | → sale_transactions.id |
| source | ENUM | NO | | — | `pos`, `qr_menu`, `delivery`, `reservation` |
| order_type | ENUM | NO | | 'dine_in' | `dine_in`, `takeaway`, `delivery` |
| status | ENUM | NO | IDX | 'pending' | `pending`, `cooking`, `ready`, `served`, `completed`, `cancelled` |
| subtotal | DECIMAL(15,2) | NO | | 0 | Subtotal |
| notes | TEXT | YES | | NULL | Catatan order |

### `order_items`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK | — | → tenants.id |
| order_id | BIGINT UNSIGNED | NO | FK, IDX | — | → orders.id |
| product_id | BIGINT UNSIGNED | NO | FK | — | → products.id |
| variant_id | BIGINT UNSIGNED | YES | FK | NULL | → product_variants.id |
| product_name | VARCHAR(255) | NO | | — | Snapshot nama |
| quantity | DECIMAL(10,3) | NO | | — | Jumlah |
| unit_price | DECIMAL(15,2) | NO | | — | Harga satuan |
| subtotal | DECIMAL(15,2) | NO | | — | Subtotal |
| notes | TEXT | YES | | NULL | Catatan item |
| status | ENUM | NO | | 'pending' | Status per item di KDS |

### `kitchen_stations`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK | — | → tenants.id |
| outlet_id | BIGINT UNSIGNED | NO | FK, IDX | — | → outlets.id |
| name | VARCHAR(100) | NO | | — | Nama station (Grill, Bar, Dessert) |
| description | VARCHAR(255) | YES | | NULL | Deskripsi |
| is_active | TINYINT(1) | NO | | 1 | Status aktif |

---

## RESERVATION TABLES

### `reservations`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | | — | Public identifier |
| reservation_number | VARCHAR(50) | NO | UK* | — | Nomor reservasi |
| outlet_id | BIGINT UNSIGNED | NO | FK | — | → outlets.id |
| member_id | BIGINT UNSIGNED | YES | FK | NULL | → members.id |
| table_id | BIGINT UNSIGNED | YES | FK | NULL | → tables.id |
| customer_name | VARCHAR(255) | NO | | — | Nama customer |
| customer_phone | VARCHAR(20) | NO | | — | Telepon |
| customer_email | VARCHAR(255) | YES | | NULL | Email |
| guest_count | INT | NO | | — | Jumlah tamu |
| reservation_date | DATE | NO | IDX | — | Tanggal reservasi |
| reservation_time | TIME | NO | | — | Waktu reservasi |
| status | ENUM | NO | IDX | 'pending' | `pending`, `confirmed`, `arrived`, `completed`, `cancelled`, `no_show` |
| notes | TEXT | YES | | NULL | Catatan |
| confirmed_at | TIMESTAMP | YES | | NULL | Waktu konfirmasi |
| arrived_at | TIMESTAMP | YES | | NULL | Waktu tiba |
| cancelled_at | TIMESTAMP | YES | | NULL | Waktu cancel |

---

## DELIVERY TABLES

### `delivery_orders`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | | — | Public identifier |
| delivery_number | VARCHAR(50) | NO | UK* | — | Nomor delivery |
| outlet_id | BIGINT UNSIGNED | NO | FK | — | → outlets.id |
| order_id | BIGINT UNSIGNED | YES | FK | NULL | → orders.id |
| sale_transaction_id | BIGINT UNSIGNED | YES | FK | NULL | → sale_transactions.id |
| driver_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → delivery_drivers.id |
| address_id | BIGINT UNSIGNED | NO | FK | — | → delivery_addresses.id |
| customer_name | VARCHAR(255) | NO | | — | Nama penerima |
| customer_phone | VARCHAR(20) | NO | | — | Telepon penerima |
| status | ENUM | NO | IDX | 'waiting' | `waiting`, `processing`, `cooking`, `ready`, `delivering`, `completed`, `cancelled` |
| shipping_fee | DECIMAL(15,2) | NO | | 0 | Ongkos kirim |
| distance_km | DECIMAL(8,2) | YES | | NULL | Jarak (km) |
| estimated_minutes | INT | YES | | NULL | Estimasi waktu (menit) |
| assigned_at | TIMESTAMP | YES | | NULL | Waktu assign driver |
| picked_up_at | TIMESTAMP | YES | | NULL | Waktu pickup |
| delivered_at | TIMESTAMP | YES | | NULL | Waktu sampai |

### `delivery_drivers`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| user_id | BIGINT UNSIGNED | YES | FK | NULL | → users.id (internal) |
| name | VARCHAR(255) | NO | | — | Nama driver |
| phone | VARCHAR(20) | NO | | — | Telepon |
| type | ENUM | NO | | 'internal' | `internal`, `external` |
| vehicle_type | VARCHAR(50) | YES | | NULL | Motor, mobil, dll |
| vehicle_number | VARCHAR(20) | YES | | NULL | Plat nomor |
| is_available | TINYINT(1) | NO | | 1 | Tersedia |
| current_latitude | DECIMAL(10,8) | YES | | NULL | GPS lat |
| current_longitude | DECIMAL(11,8) | YES | | NULL | GPS lng |

### `delivery_addresses`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK | — | → tenants.id |
| member_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → members.id |
| label | VARCHAR(50) | NO | | — | Label (Rumah, Kantor) |
| recipient_name | VARCHAR(255) | NO | | — | Nama penerima |
| phone | VARCHAR(20) | NO | | — | Telepon |
| address | TEXT | NO | | — | Alamat lengkap |
| latitude | DECIMAL(10,8) | YES | | NULL | GPS lat |
| longitude | DECIMAL(11,8) | YES | | NULL | GPS lng |
| is_default | TINYINT(1) | NO | | 0 | Alamat default |

### `delivery_tracking_points`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| delivery_order_id | BIGINT UNSIGNED | NO | FK, IDX | — | → delivery_orders.id |
| latitude | DECIMAL(10,8) | NO | | — | GPS latitude |
| longitude | DECIMAL(11,8) | NO | | — | GPS longitude |
| recorded_at | TIMESTAMP | NO | | CURRENT | Waktu rekam |

### `delivery_ratings`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| delivery_order_id | BIGINT UNSIGNED | NO | FK, UK | — | → delivery_orders.id |
| rating | TINYINT | NO | | — | 1-5 bintang |
| comment | TEXT | YES | | NULL | Komentar |