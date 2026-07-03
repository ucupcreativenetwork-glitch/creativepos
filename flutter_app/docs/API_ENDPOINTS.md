# CreativePOS Mobile — API Endpoint Map

Base URL: `{SERVER}/api/v1`  
Auth: `Authorization: Bearer {sanctum_token}`

## Health

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/health` | No | Server setup validation |

## Auth

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| POST | `/auth/login` | No | Login |
| POST | `/auth/login/2fa` | No | 2FA verify |
| POST | `/auth/logout` | Yes | Logout |
| GET | `/auth/me` | Yes | Auto login / session |
| POST | `/auth/forgot-password` | No | Reset password |
| POST | `/auth/reset-password` | No | Reset password |
| POST | `/auth/otp/email` | No | OTP email |
| POST | `/auth/otp/whatsapp` | No | OTP WhatsApp |
| POST | `/auth/otp/verify` | No | OTP verify |
| GET | `/auth/sessions` | Yes | Active sessions |
| DELETE | `/auth/sessions/{id}` | Yes | Revoke session |

## Dashboard

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/dashboard/kpi` | Yes | KPI cards |
| GET | `/dashboard/charts/sales` | Yes | Sales chart |
| GET | `/dashboard/charts/products` | Yes | Top products |
| GET | `/dashboard/charts/customers` | Yes | Member growth |
| GET | `/dashboard/charts/outlets` | Yes | Outlet comparison |
| GET | `/dashboard/live-feed` | Yes | Recent sales |
| GET | `/dashboard/outlets` | Yes | Outlet picker |

## POS

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/pos/catalog/products` | Yes | Product list |
| GET | `/pos/catalog/categories` | Yes | Categories |
| GET | `/pos/catalog/payment-methods` | Yes | Payment methods |
| GET | `/pos/shifts/current` | Yes | Active shift |
| POST | `/pos/shifts/open` | Yes | Open shift |
| POST | `/pos/shifts/{id}/close` | Yes | Close shift |
| GET | `/pos/shifts/{id}/report` | Yes | Shift report |
| GET | `/pos/held` | Yes | Held bills |
| POST | `/pos/held` | Yes | Hold bill |
| POST | `/pos/held/{id}/resume` | Yes | Resume bill |
| DELETE | `/pos/held/{id}` | Yes | Delete held |
| GET | `/pos/transactions` | Yes | History |
| POST | `/pos/transactions` | Yes | Checkout (idempotency header) |
| GET | `/pos/transactions/{uuid}` | Yes | Detail |
| POST | `/pos/transactions/{uuid}/void` | Yes | Void |
| GET | `/pos/transactions/{uuid}/receipt` | Yes | Receipt data |

## Inventory

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/inventory/products` | Yes | Product list |
| GET | `/inventory/products/barcode/{code}` | Yes | Scan barcode |
| GET | `/inventory/products/{id}` | Yes | Detail |
| GET | `/inventory/stocks` | Yes | Stock levels |
| GET | `/inventory/stocks/alerts` | Yes | Low stock |
| GET | `/inventory/stocks/movements` | Yes | Movements |
| POST | `/inventory/stocks/in` | Yes | Stock in |
| POST | `/inventory/stocks/out` | Yes | Stock out |
| POST | `/inventory/stocks/adjustment` | Yes | Adjustment |

## Members & Wallet

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/members` | Yes | Member list |
| POST | `/members` | Yes | Register |
| GET | `/members/{id}` | Yes | Detail |
| GET | `/members/code/{code}` | Yes | Barcode lookup |
| GET | `/members/qr/{token}` | Yes | QR lookup |
| GET | `/members/{id}/points` | Yes | Points |
| POST | `/members/{id}/points/redeem` | Yes | Redeem |
| GET | `/wallet/{member}` | Yes | Wallet balance |
| GET | `/wallet/{member}/transactions` | Yes | Wallet history |

## QR Menu (Public)

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/public/menu/{tenant}/{outlet}` | No | Menu |
| GET | `/public/menu/{tenant}/{outlet}/table/{token}` | No | Table menu |
| POST | `/public/orders` | No | Guest order |
| GET | `/public/orders/{uuid}/track` | No | Order status |

## Kitchen / Orders

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/kitchen/queue` | Yes | KDS queue |
| PATCH | `/kitchen/orders/{id}/bump` | Yes | Bump status |
| GET | `/orders` | Yes | Order list |
| PATCH | `/orders/{id}/status` | Yes | Update status |

## Reservations

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/reservations` | Yes | List |
| POST | `/reservations` | Yes | Create |
| GET | `/reservations/{id}` | Yes | Detail |
| PATCH | `/reservations/{id}/status` | Yes | Confirm/cancel/check-in |

## Delivery

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/delivery/orders` | Yes | Driver orders |
| PATCH | `/delivery/orders/{id}/status` | Yes | Status update |
| POST | `/delivery/orders/{id}/location` | Yes | GPS ping |

## CRM

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/crm/tickets` | Yes | Tickets |
| POST | `/crm/tickets` | Yes | Create |
| POST | `/crm/tickets/{id}/messages` | Yes | Chat |
| GET | `/crm/faqs` | Yes | FAQ |

## Notifications

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/notifications` | Yes | Inbox |
| GET | `/notifications/unread-count` | Yes | Badge |
| POST | `/notifications/read-all` | Yes | Mark read |
| POST | `/devices/fcm-token` | Yes | FCM register |

## Settings

| Method | Path | Auth | Mobile Use |
|--------|------|------|------------|
| GET | `/settings/tenant` | Yes | Business profile |
| GET | `/settings/outlets` | Yes | Outlets |
| POST | `/uploads` | Yes | Image upload |