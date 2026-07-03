# TAHAP 3 — API Documentation

## CreativePOS REST API v1

**Base URL:** `https://api.creativepos.app/api/v1`  
**Auth:** Bearer Token (Laravel Sanctum)  
**Content-Type:** `application/json`  
**Rate Limit:** 60 req/min (authenticated), 20 req/min (public)

---

## Response Format

### Success

```json
{
  "success": true,
  "message": "Operation successful",
  "data": { },
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 100
  }
}
```

### Error

```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["The email field is required."]
  }
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No Content |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden (permission/tenant/feature) |
| 404 | Not Found |
| 422 | Validation Error |
| 429 | Rate Limited |
| 500 | Server Error |

---

## 1. Authentication API

### POST `/auth/register`

Register new tenant + owner account.

**Body:**
```json
{
  "business_name": "Warung Makan Pak Budi",
  "owner_name": "Budi Santoso",
  "email": "budi@warung.com",
  "phone": "081234567890",
  "password": "SecurePass123!",
  "password_confirmation": "SecurePass123!"
}
```

**Response:** `201` — `{ tenant, user, token }`

---

### POST `/auth/login`

**Body:**
```json
{
  "email": "budi@warung.com",
  "password": "SecurePass123!",
  "device_name": "POS Terminal 1"
}
```

**Response:** `200`
```json
{
  "data": {
    "token": "1|abc...",
    "user": { "id": 1, "name": "Budi", "email": "...", "roles": ["owner"] },
    "permissions": ["pos.create", "inventory.view", "..."],
    "tenant": { "id": 1, "name": "Warung Makan Pak Budi", "slug": "warung-makan" },
    "requires_2fa": false
  }
}
```

---

### POST `/auth/login/2fa`

**Body:** `{ "code": "123456" }`  
**Response:** `200` — Full auth response

---

### POST `/auth/otp/whatsapp`

**Body:** `{ "phone": "081234567890", "purpose": "login" }`  
**Response:** `200` — `{ "expires_in": 300 }`

---

### POST `/auth/otp/verify`

**Body:** `{ "identifier": "081234567890", "code": "123456", "channel": "whatsapp" }`

---

### POST `/auth/forgot-password`

**Body:** `{ "email": "budi@warung.com" }`

---

### POST `/auth/reset-password`

**Body:** `{ "token": "...", "email": "...", "password": "...", "password_confirmation": "..." }`

---

### POST `/auth/google`

**Body:** `{ "access_token": "google_oauth_token" }`

---

### GET `/auth/me`

**Auth:** Required  
**Response:** Current user + tenant + permissions

---

### POST `/auth/logout`

**Auth:** Required — Revoke current token

---

### GET `/auth/sessions`

**Auth:** Required — List active sessions

---

### DELETE `/auth/sessions/{id}`

**Auth:** Required — Revoke specific session

---

### GET `/auth/login-history`

**Auth:** Required — Paginated login history

---

## 2. Dashboard API

### GET `/dashboard/kpi`

**Auth:** Required | **Permission:** `dashboard.view`

**Query:** `?outlet_id=1&date_from=2026-06-01&date_to=2026-06-25`

**Response:**
```json
{
  "data": {
    "revenue_today": 5500000,
    "revenue_week": 32000000,
    "revenue_month": 125000000,
    "revenue_year": 890000000,
    "transactions_today": 87,
    "new_members_today": 5,
    "active_reservations": 3,
    "active_deliveries": 2,
    "open_tickets": 1,
    "stock_alerts": 4
  }
}
```

---

### GET `/dashboard/charts/sales`

**Query:** `?period=daily&outlet_id=1&days=30`

---

### GET `/dashboard/charts/products`

**Query:** `?outlet_id=1&limit=10&period=month`

---

### GET `/dashboard/charts/customers`

---

### GET `/dashboard/live-feed`

**Auth:** Required — WebSocket alternative (polling)  
**Response:** Recent transactions (last 10)

---

## 3. Inventory API

### Products

| Method | Endpoint | Permission | Description |
|--------|----------|------------|-------------|
| GET | `/inventory/products` | `inventory.view` | List products (paginated, filterable) |
| GET | `/inventory/products/{id}` | `inventory.view` | Product detail |
| POST | `/inventory/products` | `inventory.create` | Create product |
| PUT | `/inventory/products/{id}` | `inventory.update` | Update product |
| DELETE | `/inventory/products/{id}` | `inventory.delete` | Soft delete |
| GET | `/inventory/products/barcode/{code}` | `inventory.view` | Find by barcode |
| POST | `/inventory/products/import` | `inventory.create` | Bulk CSV import |
| GET | `/inventory/products/export` | `inventory.view` | Export CSV |

**POST `/inventory/products` Body:**
```json
{
  "name": "Nasi Goreng Spesial",
  "sku": "NGS-001",
  "barcode": "8991234567890",
  "category_id": 1,
  "sub_category_id": 2,
  "base_price": 25000,
  "cost_price": 12000,
  "type": "simple",
  "track_stock": true,
  "min_stock": 10,
  "show_in_menu": true,
  "show_in_pos": true,
  "variants": [
    { "name": "Regular", "price": 25000 },
    { "name": "Large", "price": 30000 }
  ]
}
```

### Categories

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/inventory/categories` | `inventory.view` |
| POST | `/inventory/categories` | `inventory.create` |
| PUT | `/inventory/categories/{id}` | `inventory.update` |
| DELETE | `/inventory/categories/{id}` | `inventory.delete` |

### Stock

| Method | Endpoint | Permission | Description |
|--------|----------|------------|-------------|
| GET | `/inventory/stocks` | `inventory.view` | Stock levels per warehouse |
| POST | `/inventory/stocks/in` | `inventory.stock-in` | Stock in |
| POST | `/inventory/stocks/out` | `inventory.stock-out` | Stock out |
| POST | `/inventory/stocks/transfer` | `inventory.stock-transfer` | Transfer antar gudang |
| POST | `/inventory/stocks/adjustment` | `inventory.stock-adjust` | Adjustment |
| GET | `/inventory/stocks/movements` | `inventory.view` | Movement history |
| GET | `/inventory/stocks/alerts` | `inventory.view` | Low stock alerts |

### Purchase Orders

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/inventory/purchase-orders` | `inventory.view` |
| POST | `/inventory/purchase-orders` | `inventory.po-create` |
| GET | `/inventory/purchase-orders/{id}` | `inventory.view` |
| POST | `/inventory/purchase-orders/{id}/submit` | `inventory.po-create` |
| POST | `/inventory/purchase-orders/{id}/approve` | `inventory.po-approve` |
| POST | `/inventory/purchase-orders/{id}/cancel` | `inventory.po-create` |
| POST | `/inventory/goods-receipts` | `inventory.grn-create` |

### Stock Opname

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/inventory/opnames` | `inventory.view` |
| POST | `/inventory/opnames` | `inventory.opname-create` |
| PUT | `/inventory/opnames/{id}/items` | `inventory.opname-create` |
| POST | `/inventory/opnames/{id}/complete` | `inventory.opname-approve` |

---

## 4. POS API

### Shifts

| Method | Endpoint | Permission | Description |
|--------|----------|------------|-------------|
| POST | `/pos/shifts/open` | `pos.shift` | Open shift |
| POST | `/pos/shifts/close` | `pos.shift` | Close shift |
| GET | `/pos/shifts/current` | `pos.shift` | Current open shift |
| GET | `/pos/shifts/{id}/report` | `pos.shift` | Shift report |

**POST `/pos/shifts/open` Body:**
```json
{ "outlet_id": 1, "opening_cash": 500000 }
```

### Transactions

| Method | Endpoint | Permission | Description |
|--------|----------|------------|-------------|
| GET | `/pos/transactions` | `pos.view` | List transactions |
| GET | `/pos/transactions/{id}` | `pos.view` | Transaction detail |
| POST | `/pos/transactions` | `pos.create` | Create transaction |
| POST | `/pos/transactions/{id}/void` | `pos.void` | Void transaction |
| POST | `/pos/transactions/{id}/refund` | `pos.refund` | Refund |
| GET | `/pos/transactions/{id}/receipt` | `pos.view` | Get receipt data |
| POST | `/pos/transactions/{id}/reprint` | `pos.view` | Reprint receipt |

**POST `/pos/transactions` Body:**
```json
{
  "outlet_id": 1,
  "order_type": "dine_in",
  "table_id": 5,
  "member_id": 12,
  "items": [
    { "product_id": 1, "variant_id": null, "quantity": 2, "notes": "no spicy" },
    { "product_id": 3, "quantity": 1 }
  ],
  "discounts": [
    { "type": "percentage", "value": 10, "name": "Member Discount" }
  ],
  "payments": [
    { "payment_method_id": 1, "amount": 50000 },
    { "payment_method_id": 3, "amount": 15000, "reference_number": "QRIS-123" }
  ],
  "notes": "VIP customer"
}
```

### Held Transactions

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/pos/held` | `pos.create` |
| POST | `/pos/held` | `pos.create` |
| POST | `/pos/held/{id}/resume` | `pos.create` |
| DELETE | `/pos/held/{id}` | `pos.create` |

### Tables

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/pos/tables` | `pos.view` |
| PUT | `/pos/tables/{id}/status` | `pos.create` |

### Promos & Vouchers

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/pos/promos` | `pos.view` |
| POST | `/pos/promos/validate` | `pos.create` |
| GET | `/pos/vouchers` | `pos.view` |
| POST | `/pos/vouchers/validate` | `pos.create` |

---

## 5. Loyalty & Member API

| Method | Endpoint | Permission | Description |
|--------|----------|------------|-------------|
| GET | `/members` | `member.view` | List members |
| POST | `/members` | `member.create` | Register member |
| GET | `/members/{id}` | `member.view` | Member detail |
| PUT | `/members/{id}` | `member.update` | Update member |
| GET | `/members/code/{code}` | `member.view` | Find by code |
| GET | `/members/qr/{token}` | `member.view` | Find by QR |
| GET | `/members/{id}/points` | `member.view` | Point balance & history |
| POST | `/members/{id}/points/redeem` | `member.redeem` | Redeem points |
| GET | `/members/tiers` | `member.view` | Tier configs |
| GET | `/members/rewards` | `member.view` | Available rewards |

---

## 6. Wallet API

| Method | Endpoint | Permission | Feature Gate |
|--------|----------|------------|-------------|
| GET | `/wallet/{memberId}` | `wallet.view` | `member_wallet` |
| GET | `/wallet/{memberId}/transactions` | `wallet.view` | `member_wallet` |
| POST | `/wallet/topup` | `wallet.topup` | `member_wallet` |
| POST | `/wallet/withdraw` | `wallet.withdraw` | `member_wallet` |
| POST | `/wallet/transfer` | `wallet.transfer` | `member_wallet` |

---

## 7. Orders & Kitchen API

| Method | Endpoint | Permission | Description |
|--------|----------|------------|-------------|
| GET | `/orders` | `order.view` | List orders |
| POST | `/orders` | `order.create` | Create order |
| GET | `/orders/{id}` | `order.view` | Order detail |
| PATCH | `/orders/{id}/status` | `order.update` | Update status |
| GET | `/kitchen/queue` | `kitchen.view` | KDS order queue |
| PATCH | `/kitchen/orders/{id}/bump` | `kitchen.update` | Bump order status |

**PATCH `/orders/{id}/status` Body:**
```json
{ "status": "cooking" }
```

---

## 8. Public QR Menu API (No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/public/menu/{tenantSlug}/{outletSlug}` | Digital menu |
| GET | `/public/menu/{tenantSlug}/{outletSlug}/table/{token}` | Table menu |
| POST | `/public/orders` | Guest checkout |
| GET | `/public/orders/{uuid}/track` | Track order status |
| POST | `/public/call-waiter` | Call waiter |
| POST | `/public/request-bill` | Request bill |

---

## 9. Reservation API

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/reservations` | `reservation.view` |
| POST | `/reservations` | `reservation.create` |
| GET | `/reservations/{id}` | `reservation.view` |
| PUT | `/reservations/{id}` | `reservation.update` |
| PATCH | `/reservations/{id}/status` | `reservation.update` |
| GET | `/reservations/calendar` | `reservation.view` |
| GET | `/reservations/slots` | `reservation.view` |

---

## 10. Delivery API

| Method | Endpoint | Permission | Feature Gate |
|--------|----------|------------|-------------|
| GET | `/delivery/orders` | `delivery.view` | `delivery` |
| POST | `/delivery/orders` | `delivery.create` | `delivery` |
| GET | `/delivery/orders/{id}` | `delivery.view` | `delivery` |
| PATCH | `/delivery/orders/{id}/status` | `delivery.update` | `delivery` |
| POST | `/delivery/orders/{id}/assign` | `delivery.assign` | `delivery` |
| POST | `/delivery/orders/{id}/location` | `delivery.update` | `delivery` |
| GET | `/delivery/drivers` | `delivery.view` | `delivery` |
| GET | `/delivery/zones` | `delivery.view` | `delivery` |
| POST | `/delivery/calculate-fee` | `delivery.create` | `delivery` |

---

## 11. CRM API

| Method | Endpoint | Permission | Feature Gate |
|--------|----------|------------|-------------|
| GET | `/crm/tickets` | `crm.view` | `crm` |
| POST | `/crm/tickets` | `crm.create` | `crm` |
| GET | `/crm/tickets/{id}` | `crm.view` | `crm` |
| PATCH | `/crm/tickets/{id}/assign` | `crm.assign` | `crm` |
| PATCH | `/crm/tickets/{id}/status` | `crm.update` | `crm` |
| POST | `/crm/tickets/{id}/messages` | `crm.update` | `crm` |
| GET | `/crm/knowledge-base` | `crm.view` | `crm` |
| GET | `/crm/faqs` | `crm.view` | `crm` |
| POST | `/crm/tickets/{id}/rate` | `crm.view` | `crm` |

---

## 12. Reporting API

| Method | Endpoint | Permission | Description |
|--------|----------|------------|-------------|
| GET | `/reports/sales` | `report.view` | Sales report |
| GET | `/reports/products` | `report.view` | Product sales |
| GET | `/reports/inventory` | `report.view` | Inventory movement |
| GET | `/reports/members` | `report.view` | Member growth |
| GET | `/reports/profit-loss` | `report.view` | P&L report |
| GET | `/reports/cash-flow` | `report.view` | Cash flow |
| GET | `/reports/shift/{id}` | `report.view` | Shift report |
| POST | `/reports/export` | `report.export` | Export PDF/Excel/CSV |
| GET | `/reports/exports` | `report.view` | List exports |
| GET | `/reports/exports/{id}/download` | `report.export` | Download file |

**GET `/reports/sales` Query:**
```
?type=daily&date_from=2026-06-01&date_to=2026-06-25&outlet_id=1&format=json
```

---

## 13. Settings API

| Method | Endpoint | Permission |
|--------|----------|------------|
| GET | `/settings/tenant` | `settings.view` |
| PUT | `/settings/tenant` | `settings.update` |
| GET | `/settings/outlets` | `settings.view` |
| POST | `/settings/outlets` | `settings.create` |
| PUT | `/settings/outlets/{id}` | `settings.update` |
| GET | `/settings/users` | `settings.view` |
| POST | `/settings/users` | `settings.create` |
| GET | `/settings/roles` | `settings.view` |
| POST | `/settings/roles` | `settings.create` |
| PUT | `/settings/roles/{id}/permissions` | `settings.update` |
| GET | `/settings/integrations` | `settings.view` |
| PUT | `/settings/integrations/{provider}` | `settings.update` |

---

## 14. Platform API (Super Admin)

**Prefix:** `/platform` | **Middleware:** `super-admin`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/platform/dashboard` | Platform KPI (MRR, tenants) |
| GET | `/platform/tenants` | List all tenants |
| POST | `/platform/tenants` | Create tenant |
| GET | `/platform/tenants/{id}` | Tenant detail |
| PATCH | `/platform/tenants/{id}/suspend` | Suspend tenant |
| PATCH | `/platform/tenants/{id}/activate` | Activate tenant |
| GET | `/platform/packages` | List packages |
| POST | `/platform/packages` | Create package |
| PUT | `/platform/packages/{id}` | Update package |
| GET | `/platform/subscriptions` | List subscriptions |
| POST | `/platform/subscriptions` | Create subscription |
| PATCH | `/platform/subscriptions/{id}/renew` | Renew |
| GET | `/platform/billing/invoices` | List invoices |
| POST | `/platform/billing/invoices` | Generate invoice |
| POST | `/platform/impersonate/{tenantId}` | Impersonate tenant |

---

## 15. WebSocket Channels

**Connection:** `wss://ws.creativepos.app`  
**Auth:** Bearer token via `/broadcasting/auth`

| Channel | Event | Payload |
|---------|-------|---------|
| `tenant.{id}.outlet.{id}.kitchen` | `OrderCreated` | order, items |
| `tenant.{id}.outlet.{id}.kitchen` | `OrderStatusUpdated` | order_id, status |
| `tenant.{id}.outlet.{id}.dashboard` | `NewTransaction` | transaction summary |
| `tenant.{id}.outlet.{id}.dashboard` | `StockAlert` | product, quantity |
| `tenant.{id}.delivery.{orderId}` | `LocationUpdated` | lat, lng, eta |
| `user.{id}` | `Notification` | title, body, data |
| `user.{id}` | `TicketAssigned` | ticket |

---

## 16. Webhook Endpoints

| Method | Endpoint | Source |
|--------|----------|--------|
| POST | `/webhooks/whatsapp` | WhatsApp Business API |
| POST | `/webhooks/payment/midtrans` | Midtrans |
| POST | `/webhooks/payment/xendit` | Xendit |

---

## 17. Query Parameters (Common)

| Parameter | Type | Description |
|-----------|------|-------------|
| `page` | int | Page number (default: 1) |
| `per_page` | int | Items per page (default: 15, max: 100) |
| `sort` | string | Sort field (prefix `-` for desc) |
| `filter[search]` | string | Full-text search |
| `filter[outlet_id]` | int | Filter by outlet |
| `filter[status]` | string | Filter by status |
| `filter[date_from]` | date | Date range start |
| `filter[date_to]` | date | Date range end |
| `include` | string | Eager load relations (comma-separated) |

**Example:**
```
GET /api/v1/inventory/products?page=1&per_page=20&sort=-created_at&filter[search]=nasi&filter[category_id]=1&include=category,variants,stocks
```