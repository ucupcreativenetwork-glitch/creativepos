# TAHAP 1 — Daftar Modul CreativePOS

## Arsitektur Modular

Sistem dibagi menjadi **16 modul inti** + **3 modul platform** (Super Admin, Billing, System).

```
┌─────────────────────────────────────────────────────────────────┐
│                    PLATFORM LAYER (Super Admin)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ Super Admin  │  │ Subscription │  │ Platform Monitoring  │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                     TENANT LAYER (Per Bisnis)                    │
│                                                                  │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │
│  │  Auth  │ │Dashboard│ │  POS  │ │Inventory│ │ Loyalty│       │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘       │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐       │
│  │ Wallet │ │QR Menu │ │Kitchen │ │  Reserv │ │Delivery│       │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘       │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐                  │
│  │  CRM   │ │WhatsApp│ │ Report │ │ Settings│                  │
│  └────────┘ └────────┘ └────────┘ └────────┘                  │
└─────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────────┐
│                    SHARED / INFRASTRUCTURE                       │
│  Multi-Tenant │ RBAC │ Audit Log │ Notification │ File Storage  │
│  WebSocket │ Queue │ Cache │ API Gateway │ PWA Service Worker   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Modul Platform (Super Admin)

### M00 — Platform Management

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Tenant Management | CRUD tenant, suspend, activate |
| Package Management | Starter, Business, Professional, Enterprise |
| Subscription Management | Aktivasi, renewal, upgrade/downgrade |
| Billing Management | Invoice, payment history, dunning |
| Platform Dashboard | Total tenant, MRR, churn, system health |
| Platform Settings | Global config, maintenance mode |

**Aktor:** Super Admin  
**Isolasi:** Tidak menggunakan `tenant_id` (platform-level tables)

---

## Modul Tenant

### M01 — Authentication & Authorization

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Login / Register | Email, Google OAuth |
| Password Management | Forgot, reset, change |
| Verification | Email, OTP, WhatsApp OTP |
| Two Factor Auth | TOTP-based 2FA |
| Session Management | Active sessions, revoke |
| Device Management | Trusted devices, fingerprint |
| Role & Permission | Spatie RBAC, 10 roles |

**Dependensi:** M00 (tenant context)  
**Tabel utama:** `users`, `roles`, `permissions`, `sessions`, `login_histories`, `devices`

---

### M02 — Dashboard

| Sub-Modul | Deskripsi |
|-----------|-----------|
| KPI Cards | Revenue (today/week/month/year) |
| Charts | Sales, customer growth, product performance |
| Alerts | Stock low, open tickets, active orders |
| Outlet Comparison | Performance per outlet |
| Real-time Feed | Live transactions, kitchen status |

**Dependensi:** M03 (POS), M04 (Inventory), M07 (Reservation), M08 (Delivery), M09 (CRM)  
**Aktor:** Owner, Manager, Supervisor

---

### M03 — Point of Sale (POS)

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Quick Sale | Barcode/QR scan, manual search |
| Transaction Management | Hold, resume, void |
| Bill Management | Split bill, merge bill |
| Payment Processing | Cash, transfer, QRIS, card, e-wallet |
| Discount Engine | %, nominal, voucher, promo |
| Refund & Return | Partial/full refund |
| Receipt | Print 58mm/80mm, reprint |
| Shift Management | Open/close shift, cash drawer |
| Table Management | Dine-in table assignment |

**Dependensi:** M04 (products), M05 (member), M06 (wallet), M10 (WhatsApp)  
**Aktor:** Cashier, Waiter, Supervisor

---

### M04 — Inventory Management

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Product Catalog | Category, sub-category, brand, SKU |
| Product Variant | Size, color, custom attributes |
| Bundle Product | Combo/bundle pricing |
| Stock Management | In, out, transfer, adjustment |
| Stock Opname | Physical count & variance |
| Warehouse | Multi warehouse per tenant |
| Outlet Stock | Per-outlet inventory level |
| Supplier | Supplier master data |
| Purchase Order | PO creation, approval, tracking |
| Goods Receipt | GRN from PO |
| Purchase Return | Return to supplier |
| Stock Alert | Low stock, expiry alert |

**Dependensi:** M03 (POS stock deduction)  
**Aktor:** Manager, Supervisor

---

### M05 — Loyalty & Member

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Member Registration | Manual, QR, barcode |
| Member Profile | Name, email, phone, birthday |
| Point System | Configurable earn rate |
| Membership Tier | Bronze, Silver, Gold, Platinum |
| Point Transaction | Earn, redeem, expire |
| Reward Engine | Voucher, cashback, product reward |
| Birthday Reward | Auto-trigger on birthday |
| Referral Program | Referral code & reward |
| Member QR/Barcode | Scannable member ID |

**Dependensi:** M03 (POS point earn), M06 (wallet)  
**Aktor:** Cashier, Customer, Manager

---

### M06 — Member Wallet

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Wallet Account | Balance per member |
| Top Up | Cash, transfer, payment gateway |
| Withdraw | Request & approval |
| Transfer | Member-to-member |
| Wallet Payment | Pay via wallet at POS |
| Transaction History | Full audit trail |
| Wallet Limit | Configurable min/max |

**Dependensi:** M05 (member), M03 (POS payment)  
**Aktor:** Customer, Cashier, Manager

---

### M07 — QR Digital Menu

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Table QR Management | Generate QR per meja (A01, VIP01, dll) |
| Digital Menu | Category, product, price, photo |
| Availability | Real-time stock status |
| Guest Cart | Add to cart without login |
| Guest Checkout | Order to kitchen/POS |
| Member Checkout | Login member, earn points |
| Menu Customization | Tenant branding, theme |

**Dependensi:** M03 (order creation), M04 (product/availability), M10 (KDS)  
**Aktor:** Customer (guest/member)

---

### M08 — Kitchen Display System (KDS)

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Order Queue | Real-time via WebSocket |
| Status Management | Pending → Cooking → Ready → Served |
| Station Filter | Grill, bar, dessert station |
| Order Timer | Elapsed time per order |
| Bump Screen | Mark complete |
| Sound Alert | New order notification |

**Dependensi:** M03, M07, M08 (delivery)  
**Aktor:** Kitchen staff

---

### M09 — Reservation

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Table Reservation | Date, time, guest count |
| Reservation Calendar | Visual calendar view |
| Status Flow | Pending → Confirmed → Arrived → Completed |
| Table Assignment | Auto/manual table assign |
| Reminder | WhatsApp & email notification |
| Walk-in | Convert walk-in to reservation |
| No-show Handling | Auto-cancel policy |

**Dependensi:** M11 (WhatsApp), M03 (table management)  
**Aktor:** Customer, Waiter, Manager

---

### M10 — Delivery

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Delivery Order | Create from POS or online |
| Status Tracking | Waiting → Processing → Cooking → Ready → Delivering → Completed |
| Driver Management | Internal & external drivers |
| Address Book | Multiple addresses per customer |
| GPS Tracking | Real-time driver location |
| Shipping Calculator | Flat rate & distance-based |
| Maps Integration | Google Maps / OpenStreetMap |
| Delivery Zone | Configurable delivery area |

**Dependensi:** M03, M04, M11 (notification)  
**Aktor:** Customer, Driver, Manager, Cashier

---

### M11 — CRM (Customer Service)

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Ticketing | Create, assign, resolve tickets |
| SLA Management | Response & resolution time |
| Multi-Channel | WhatsApp, Telegram, Email, Website |
| Priority | Low, Medium, High, Critical |
| Knowledge Base | FAQ, documentation, tutorials |
| Customer Rating | 1–5 star feedback |
| Agent Dashboard | Queue, performance metrics |
| Canned Responses | Template replies |

**Dependensi:** M11 (WhatsApp channel)  
**Aktor:** Customer Service, Manager

---

### M12 — WhatsApp Integration

| Sub-Modul | Deskripsi |
|-----------|-----------|
| OTP Service | Login/register OTP |
| Transaction Notification | Invoice, payment receipt |
| Reservation Reminder | H-1, H-0 reminder |
| Loyalty Notification | Point earned, tier upgrade |
| Promo Broadcast | Bulk promo message |
| Template Management | WA message templates |
| Webhook Handler | Incoming message handler |

**Dependensi:** External WhatsApp Business API  
**Aktor:** System (automated), Manager (broadcast)

---

### M13 — Reporting & Analytics

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Sales Report | Daily, weekly, monthly, yearly |
| Product Report | Best seller, slow mover |
| Customer Report | Activity, retention |
| Member Report | Growth, tier distribution |
| Inventory Report | Movement, valuation |
| Purchase Report | PO, GRN, returns |
| Financial Report | Profit/loss, cash flow |
| Export Engine | PDF, Excel, CSV |
| Scheduled Report | Auto-email reports |

**Dependensi:** Semua modul transaksional  
**Aktor:** Owner, Manager

---

### M14 — Settings & Configuration

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Tenant Profile | Business name, logo, address |
| Outlet Management | CRUD outlet |
| Tax Configuration | PPN, service charge |
| Payment Methods | Enable/disable per outlet |
| Printer Configuration | Printer per outlet/station |
| Notification Preferences | Email, WA, push |
| Business Hours | Operating hours per outlet |
| Receipt Template | Custom receipt layout |
| Integration Settings | Payment gateway, WA API keys |

**Aktor:** Owner, Manager

---

### M15 — Audit & Security

| Sub-Modul | Deskripsi |
|-----------|-----------|
| Audit Log | All CRUD operations |
| Activity Log | User actions |
| Login History | IP, device, timestamp |
| Device Tracking | Registered devices |
| Rate Limiting | API & auth throttling |
| Data Export | GDPR compliance export |
| IP Whitelist | Optional IP restriction |

**Aktor:** Owner, Super Admin

---

## Matriks Dependensi Modul

```
        M00 M01 M02 M03 M04 M05 M06 M07 M08 M09 M10 M11 M12 M13 M14 M15
M00      -   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·
M01      ·   -   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ·   ✓
M02      ·   ✓   -   ✓   ✓   ·   ·   ·   ·   ✓   ✓   ✓   ·   ✓   ·   ·
M03      ·   ✓   ✓   -   ✓   ✓   ✓   ✓   ✓   ·   ✓   ·   ✓   ✓   ✓   ✓
M04      ·   ✓   ✓   ✓   -   ·   ·   ✓   ·   ·   ·   ·   ·   ✓   ✓   ✓
M05      ·   ✓   ·   ✓   ·   -   ✓   ✓   ·   ·   ·   ·   ✓   ✓   ✓   ✓
M06      ·   ✓   ·   ✓   ·   ✓   -   ·   ·   ·   ·   ·   ·   ✓   ✓   ✓
M07      ·   ·   ·   ✓   ✓   ✓   ·   -   ✓   ·   ·   ·   ·   ·   ✓   ·
M08      ·   ·   ·   ✓   ·   ·   ·   ✓   -   ·   ✓   ·   ·   ·   ·   ·
M09      ·   ·   ✓   ✓   ·   ·   ·   ·   ·   -   ·   ·   ✓   ✓   ✓   ·
M10      ·   ·   ✓   ✓   ·   ·   ·   ·   ✓   ·   -   ·   ✓   ✓   ✓   ·
M11      ·   ·   ✓   ·   ·   ·   ·   ·   ·   ✓   ·   -   ✓   ✓   ·   ✓
M12      ·   ✓   ·   ✓   ·   ✓   ·   ·   ·   ✓   ✓   ✓   -   ·   ✓   ·
M13      ·   ✓   ·   ✓   ✓   ✓   ✓   ·   ·   ✓   ✓   ✓   ·   -   ·   ✓
M14      ·   ✓   ·   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ✓   ·   -   ✓
M15      ·   ✓   ·   ✓   ✓   ✓   ✓   ·   ·   ·   ·   ✓   ·   ✓   ✓   -
```

✓ = depends on / provides data to

---

## Paket Langganan vs Modul

| Modul | Starter | Business | Professional | Enterprise |
|-------|---------|----------|--------------|------------|
| Auth & RBAC | ✅ | ✅ | ✅ | ✅ |
| Dashboard (basic) | ✅ | ✅ | ✅ | ✅ |
| Dashboard (advanced) | ❌ | ✅ | ✅ | ✅ |
| POS | ✅ (1 outlet) | ✅ (3 outlet) | ✅ (10 outlet) | ✅ (unlimited) |
| Inventory (basic) | ✅ | ✅ | ✅ | ✅ |
| Inventory (multi-warehouse) | ❌ | ✅ | ✅ | ✅ |
| Loyalty Member | ❌ | ✅ | ✅ | ✅ |
| Member Wallet | ❌ | ❌ | ✅ | ✅ |
| QR Digital Menu | ❌ | ✅ | ✅ | ✅ |
| Kitchen Display | ❌ | ✅ | ✅ | ✅ |
| Reservation | ❌ | ✅ | ✅ | ✅ |
| Delivery | ❌ | ❌ | ✅ | ✅ |
| CRM | ❌ | ❌ | ✅ | ✅ |
| WhatsApp | ❌ | ✅ (limited) | ✅ | ✅ (unlimited) |
| Reporting (basic) | ✅ | ✅ | ✅ | ✅ |
| Reporting (advanced) | ❌ | ❌ | ✅ | ✅ |
| API Access | ❌ | ❌ | ✅ | ✅ |
| Custom Domain | ❌ | ❌ | ❌ | ✅ |
| Priority Support | ❌ | ❌ | ❌ | ✅ |