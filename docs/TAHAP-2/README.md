# TAHAP 2 — Database Design

## Status: ✅ SELESAI

**Tanggal Selesai:** 25 Juni 2026  
**Database Engine:** MySQL 8.0  
**Charset:** `utf8mb4_unicode_ci`  
**Collation:** `utf8mb4_unicode_ci`

---

## Deliverables

| # | Dokumen | File | Status |
|---|---------|------|--------|
| 1 | ERD Overview | [01-erd-overview.md](./01-erd-overview.md) | ✅ |
| 2 | Database Schema (SQL DDL) | [02-database-schema.sql](./02-database-schema.sql) | ✅ |
| 3 | Table Relations & Indexes | [03-table-relations.md](./03-table-relations.md) | ✅ |
| 4 | Data Dictionary — Platform & Auth | [04-data-dictionary-platform-auth.md](./04-data-dictionary-platform-auth.md) | ✅ |
| 5 | Data Dictionary — Inventory & POS | [05-data-dictionary-inventory-pos.md](./05-data-dictionary-inventory-pos.md) | ✅ |
| 6 | Data Dictionary — Orders & Operations | [06-data-dictionary-orders-ops.md](./06-data-dictionary-orders-ops.md) | ✅ |
| 7 | Data Dictionary — CRM & System | [07-data-dictionary-crm-system.md](./07-data-dictionary-crm-system.md) | ✅ |

---

## Statistik Database

| Metric | Value |
|--------|-------|
| **Total Tabel** | 156 |
| **Platform Tables** | 8 (tanpa `tenant_id`) |
| **Tenant Tables** | 148 (dengan `tenant_id`) |
| **Reference Tables** | 5 (shared lookup) |
| **Spatie Permission** | 5 |
| **Foreign Keys** | 280+ |
| **Indexes** | 400+ |

---

## Multi-Tenant Strategy

```
┌─────────────────────────────────────────────────────────┐
│                  SHARED DATABASE                         │
│                                                          │
│  ┌─────────────────┐    ┌─────────────────────────────┐ │
│  │ Platform Tables │    │ Tenant Tables               │ │
│  │ (no tenant_id)  │    │ (tenant_id on every row)    │ │
│  │                 │    │                             │ │
│  │ • tenants       │    │ • products                  │ │
│  │ • packages      │    │ • sale_transactions         │ │
│  │ • subscriptions │    │ • members                   │ │
│  │ • billing_*     │    │ • orders                    │ │
│  └─────────────────┘    │ • ... (148 tables)          │ │
│                          └─────────────────────────────┘ │
│                                                          │
│  Isolation: Laravel Global Scope + Policy + Middleware   │
└─────────────────────────────────────────────────────────┘
```

### Konvensi Kolom Standar

Setiap tabel tenant-scoped WAJIB memiliki:

| Kolom | Tipe | Deskripsi |
|-------|------|-----------|
| `id` | BIGINT UNSIGNED PK AI | Primary key |
| `tenant_id` | BIGINT UNSIGNED FK | Referensi ke `tenants.id` |
| `uuid` | CHAR(36) UNIQUE | Public identifier |
| `created_at` | TIMESTAMP | Waktu dibuat |
| `updated_at` | TIMESTAMP | Waktu diupdate |
| `deleted_at` | TIMESTAMP NULL | Soft delete (opsional) |

---

## Domain Grouping

| Domain | Tables | Prefix/Group |
|--------|--------|--------------|
| Platform & SaaS | 8 | `tenants`, `packages`, `subscriptions`, `billing_*` |
| Authentication | 12 | `users`, `otp_*`, `login_*`, `devices` |
| RBAC (Spatie) | 5 | `roles`, `permissions`, `model_has_*` |
| Tenant & Outlet | 10 | `outlets`, `tenant_*`, `business_hours` |
| Reference Data | 5 | `countries`, `units_of_measure` |
| Inventory | 29 | `products`, `stocks`, `purchase_*` |
| Point of Sale | 20 | `sale_*`, `shifts`, `tables` |
| Loyalty & Member | 12 | `members`, `points`, `rewards` |
| Wallet | 5 | `wallets`, `wallet_*` |
| Orders & KDS | 8 | `orders`, `kitchen_*` |
| Reservation | 4 | `reservations` |
| Delivery | 10 | `delivery_*` |
| CRM | 10 | `support_tickets`, `knowledge_*` |
| WhatsApp | 5 | `whatsapp_*` |
| Notifications | 3 | `notifications` |
| Audit & Security | 3 | `audit_logs`, `activity_logs` |
| Reporting | 4 | `scheduled_reports` |
| Finance | 6 | `expenses`, `journal_*` |

---

## Langkah Selanjutnya → TAHAP 3

TAHAP 3 akan mencakup:

1. Struktur Backend (Laravel modular)
2. Struktur Frontend (Next.js App Router)
3. Struktur API (REST endpoints)
4. Struktur Deployment (Docker Compose)

---

*CreativePOS by Creative Network*