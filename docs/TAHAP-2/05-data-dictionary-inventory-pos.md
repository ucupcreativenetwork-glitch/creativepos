# TAHAP 2 — Data Dictionary: Inventory & POS

---

## INVENTORY TABLES

### `products`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | UK | — | Public identifier |
| category_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → categories.id |
| sub_category_id | BIGINT UNSIGNED | YES | FK | NULL | → sub_categories.id |
| brand_id | BIGINT UNSIGNED | YES | FK | NULL | → brands.id |
| unit_id | BIGINT UNSIGNED | YES | FK | NULL | → units_of_measure.id |
| sku | VARCHAR(100) | NO | UK* | — | Stock Keeping Unit |
| barcode | VARCHAR(100) | YES | IDX | NULL | Barcode (EAN-13/Code128) |
| name | VARCHAR(255) | NO | FT | — | Nama produk |
| description | TEXT | YES | FT | NULL | Deskripsi |
| type | ENUM | NO | | 'simple' | `simple`, `variant`, `bundle`, `service` |
| base_price | DECIMAL(15,2) | NO | | 0 | Harga jual default |
| cost_price | DECIMAL(15,2) | NO | | 0 | Harga pokok (HPP) |
| min_stock | INT | NO | | 0 | Stok minimum (alert) |
| max_stock | INT | YES | | NULL | Stok maksimum |
| track_stock | TINYINT(1) | NO | | 1 | Lacak stok |
| is_active | TINYINT(1) | NO | | 1 | Produk aktif |
| is_available | TINYINT(1) | NO | | 1 | Tersedia dijual |
| show_in_menu | TINYINT(1) | NO | | 1 | Tampil di QR menu |
| show_in_pos | TINYINT(1) | NO | | 1 | Tampil di POS |
| preparation_time | INT | YES | | NULL | Waktu persiapan (menit) |

### `product_variants`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| product_id | BIGINT UNSIGNED | NO | FK | — | → products.id |
| sku | VARCHAR(100) | NO | UK* | — | SKU variant |
| barcode | VARCHAR(100) | YES | | NULL | Barcode variant |
| name | VARCHAR(255) | NO | | — | Nama variant (e.g. "Large") |
| attributes | JSON | YES | | NULL | `{"size":"L","color":"Red"}` |
| price | DECIMAL(15,2) | NO | | — | Harga variant |
| cost_price | DECIMAL(15,2) | NO | | 0 | HPP variant |

### `product_stocks`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| product_id | BIGINT UNSIGNED | NO | FK | — | → products.id |
| variant_id | BIGINT UNSIGNED | YES | FK | NULL | → product_variants.id |
| warehouse_id | BIGINT UNSIGNED | NO | FK | — | → warehouses.id |
| quantity | DECIMAL(12,3) | NO | | 0 | Jumlah stok |
| reserved_quantity | DECIMAL(12,3) | NO | | 0 | Stok reserved (order) |
| average_cost | DECIMAL(15,2) | NO | | 0 | Rata-rata HPP |

### `stock_movements`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| product_id | BIGINT UNSIGNED | NO | FK, IDX | — | → products.id |
| variant_id | BIGINT UNSIGNED | YES | | NULL | → product_variants.id |
| warehouse_id | BIGINT UNSIGNED | NO | FK | — | → warehouses.id |
| type | ENUM | NO | | — | `in`, `out`, `transfer_in`, `transfer_out`, `adjustment`, `sale`, `return`, `opname` |
| quantity | DECIMAL(12,3) | NO | | — | Jumlah pergerakan |
| before_quantity | DECIMAL(12,3) | NO | | — | Stok sebelum |
| after_quantity | DECIMAL(12,3) | NO | | — | Stok sesudah |
| reference_type | VARCHAR(100) | YES | IDX | NULL | Polymorphic type |
| reference_id | BIGINT UNSIGNED | YES | | NULL | Polymorphic ID |
| notes | TEXT | YES | | NULL | Catatan |
| created_by | BIGINT UNSIGNED | YES | | NULL | → users.id |

### `purchase_orders`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | | — | Public identifier |
| po_number | VARCHAR(50) | NO | UK* | — | Nomor PO |
| supplier_id | BIGINT UNSIGNED | NO | FK | — | → suppliers.id |
| warehouse_id | BIGINT UNSIGNED | NO | FK | — | → warehouses.id |
| status | ENUM | NO | | 'draft' | `draft`, `pending_approval`, `approved`, `ordered`, `partial`, `received`, `cancelled` |
| subtotal | DECIMAL(15,2) | NO | | 0 | Subtotal |
| tax_amount | DECIMAL(15,2) | NO | | 0 | Pajak |
| total_amount | DECIMAL(15,2) | NO | | 0 | Total |
| expected_date | DATE | YES | | NULL | Estimasi tiba |
| approved_by | BIGINT UNSIGNED | YES | | NULL | → users.id |
| approved_at | TIMESTAMP | YES | | NULL | Waktu approval |

### `suppliers`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | | — | Public identifier |
| code | VARCHAR(50) | NO | UK* | — | Kode supplier |
| name | VARCHAR(255) | NO | | — | Nama supplier |
| contact_person | VARCHAR(255) | YES | | NULL | Contact person |
| phone | VARCHAR(20) | YES | | NULL | Telepon |
| email | VARCHAR(255) | YES | | NULL | Email |
| payment_terms | VARCHAR(100) | YES | | NULL | Termin pembayaran |

---

## POS TABLES

### `sale_transactions`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| uuid | CHAR(36) | NO | UK | — | Public identifier |
| transaction_number | VARCHAR(50) | NO | UK* | — | Nomor transaksi (TRX-20260625-0001) |
| outlet_id | BIGINT UNSIGNED | NO | FK, IDX | — | → outlets.id |
| shift_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → shifts.id |
| cashier_id | BIGINT UNSIGNED | NO | FK | — | → users.id |
| member_id | BIGINT UNSIGNED | YES | FK, IDX | NULL | → members.id |
| table_id | BIGINT UNSIGNED | YES | FK | NULL | → tables.id |
| order_id | BIGINT UNSIGNED | YES | FK | NULL | → orders.id |
| order_type | ENUM | NO | | 'quick_sale' | `dine_in`, `takeaway`, `delivery`, `quick_sale` |
| status | ENUM | NO | IDX | 'pending' | `pending`, `completed`, `voided`, `refunded`, `partial_refund` |
| subtotal | DECIMAL(15,2) | NO | | 0 | Subtotal sebelum diskon |
| discount_total | DECIMAL(15,2) | NO | | 0 | Total diskon |
| tax_total | DECIMAL(15,2) | NO | | 0 | Total pajak |
| service_charge | DECIMAL(15,2) | NO | | 0 | Service charge |
| grand_total | DECIMAL(15,2) | NO | | 0 | Total akhir |
| paid_total | DECIMAL(15,2) | NO | | 0 | Total dibayar |
| change_amount | DECIMAL(15,2) | NO | | 0 | Kembalian |
| points_earned | INT | NO | | 0 | Poin diperoleh |
| points_redeemed | INT | NO | | 0 | Poin ditukar |
| completed_at | TIMESTAMP | YES | | NULL | Waktu selesai |

### `sale_transaction_items`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK | — | → tenants.id |
| transaction_id | BIGINT UNSIGNED | NO | FK, IDX | — | → sale_transactions.id |
| product_id | BIGINT UNSIGNED | NO | FK, IDX | — | → products.id |
| variant_id | BIGINT UNSIGNED | YES | FK | NULL | → product_variants.id |
| product_name | VARCHAR(255) | NO | | — | Snapshot nama produk |
| sku | VARCHAR(100) | NO | | — | Snapshot SKU |
| quantity | DECIMAL(10,3) | NO | | — | Jumlah |
| unit_price | DECIMAL(15,2) | NO | | — | Harga satuan |
| discount_amount | DECIMAL(15,2) | NO | | 0 | Diskon item |
| tax_amount | DECIMAL(15,2) | NO | | 0 | Pajak item |
| subtotal | DECIMAL(15,2) | NO | | — | Subtotal item |
| notes | TEXT | YES | | NULL | Catatan (e.g. "no ice") |

### `sale_payments`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| transaction_id | BIGINT UNSIGNED | NO | FK, IDX | — | → sale_transactions.id |
| payment_method_id | BIGINT UNSIGNED | NO | FK | — | → payment_methods.id |
| amount | DECIMAL(15,2) | NO | | — | Jumlah pembayaran |
| reference_number | VARCHAR(255) | YES | | NULL | No. referensi (transfer/QRIS) |
| gateway_response | JSON | YES | | NULL | Response payment gateway |
| status | ENUM | NO | | 'completed' | `pending`, `completed`, `failed`, `refunded` |
| paid_at | TIMESTAMP | NO | | CURRENT | Waktu bayar |

### `shifts`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| outlet_id | BIGINT UNSIGNED | NO | FK, IDX | — | → outlets.id |
| cashier_id | BIGINT UNSIGNED | NO | FK, IDX | — | → users.id |
| shift_number | VARCHAR(50) | NO | | — | Nomor shift |
| status | ENUM | NO | | 'open' | `open`, `closed` |
| opening_cash | DECIMAL(15,2) | NO | | 0 | Kas awal |
| closing_cash | DECIMAL(15,2) | YES | | NULL | Kas akhir |
| expected_cash | DECIMAL(15,2) | YES | | NULL | Kas seharusnya |
| cash_difference | DECIMAL(15,2) | YES | | NULL | Selisih kas |
| total_sales | DECIMAL(15,2) | NO | | 0 | Total penjualan shift |
| total_transactions | INT | NO | | 0 | Jumlah transaksi |
| opened_at | TIMESTAMP | NO | IDX | — | Waktu buka |
| closed_at | TIMESTAMP | YES | | NULL | Waktu tutup |

### `tables`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| outlet_id | BIGINT UNSIGNED | NO | FK | — | → outlets.id |
| area_id | BIGINT UNSIGNED | YES | FK | NULL | → table_areas.id |
| table_number | VARCHAR(20) | NO | UK* | — | Nomor meja (A01, VIP01) |
| name | VARCHAR(100) | YES | | NULL | Nama meja |
| capacity | INT | NO | | 4 | Kapasitas orang |
| status | ENUM | NO | | 'available' | `available`, `occupied`, `reserved`, `cleaning` |

### `promos`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| name | VARCHAR(255) | NO | | — | Nama promo |
| code | VARCHAR(50) | YES | IDX | NULL | Kode promo |
| type | ENUM | NO | | — | `percentage`, `nominal`, `buy_x_get_y`, `bundle` |
| value | DECIMAL(15,2) | NO | | — | Nilai diskon |
| min_purchase | DECIMAL(15,2) | YES | | NULL | Min pembelian |
| max_discount | DECIMAL(15,2) | YES | | NULL | Maks diskon |
| starts_at | TIMESTAMP | NO | | — | Mulai |
| ends_at | TIMESTAMP | NO | | — | Berakhir |
| usage_limit | INT | YES | | NULL | Batas penggunaan |
| usage_count | INT | NO | | 0 | Sudah dipakai |

### `vouchers`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| code | VARCHAR(50) | NO | UK* | — | Kode voucher |
| name | VARCHAR(255) | NO | | — | Nama voucher |
| type | ENUM | NO | | — | `percentage`, `nominal`, `free_product` |
| value | DECIMAL(15,2) | NO | | — | Nilai voucher |
| max_uses | INT | YES | | NULL | Maks penggunaan |
| used_count | INT | NO | | 0 | Sudah dipakai |
| expires_at | TIMESTAMP | YES | | NULL | Kadaluarsa |

### `refunds`

| Column | Type | Null | Key | Default | Description |
|--------|------|------|-----|---------|-------------|
| id | BIGINT UNSIGNED | NO | PK, AI | — | Primary key |
| tenant_id | BIGINT UNSIGNED | NO | FK, IDX | — | → tenants.id |
| refund_number | VARCHAR(50) | NO | | — | Nomor refund |
| transaction_id | BIGINT UNSIGNED | NO | FK, IDX | — | → sale_transactions.id |
| type | ENUM | NO | | — | `full`, `partial` |
| reason | TEXT | NO | | — | Alasan refund |
| amount | DECIMAL(15,2) | NO | | — | Jumlah refund |
| status | ENUM | NO | | 'pending' | `pending`, `approved`, `completed`, `rejected` |
| approved_by | BIGINT UNSIGNED | YES | | NULL | → users.id (supervisor) |
| created_by | BIGINT UNSIGNED | NO | | — | → users.id (cashier) |