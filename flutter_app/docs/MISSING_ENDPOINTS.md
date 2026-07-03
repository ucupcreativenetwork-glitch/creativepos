# Endpoint yang Belum Tersedia di Backend

Daftar fitur mobile yang membutuhkan endpoint baru. **Jangan implementasi logika bisnis di mobile** — tambahkan di Laravel.

## Prioritas Tinggi

| Fitur Mobile | Endpoint yang Diperlukan | Catatan |
|--------------|-------------------------|---------|
| Refresh Token | `POST /auth/refresh-token` | Saat ini Sanctum token statis; mobile pakai `/auth/me` untuk validasi |
| Split Bill | `POST /pos/transactions/{uuid}/split` | Belum ada di POS module |
| Merge Bill | `POST /pos/held/merge` | Belum ada |
| Refund | `POST /pos/transactions/{uuid}/refund` | Hanya `void` tersedia |
| Stock Opname | `POST /inventory/stocks/opname` | Gunakan sementara `stocks/adjustment` |
| Stock Transfer | `POST /inventory/stocks/transfer` | Belum ada |
| Voucher validate | `POST /pos/vouchers/validate` | Diskon via array `discounts` di transaction |
| Promo list | `GET /pos/promotions` | Belum ada endpoint dedicated |
| Delivery proof | `POST /delivery/orders/{id}/proof` + upload | Belum ada |
| Mobile app config | `GET /mobile/config` | Versi min, feature flags |

## Prioritas Sedang

| Fitur | Endpoint | Catatan |
|-------|----------|---------|
| Biometric register | Client-only | Tidak perlu API |
| SSL pinning pins | Client-only | Tidak perlu API |
| Printer templates | Client-only | Receipt dari `/pos/transactions/{uuid}/receipt` |
| WebSocket KDS | Reverb `ws://host/ws` | Polling `/kitchen/queue` sebagai fallback |

## Yang Sudah Cukup

- Login, logout, 2FA, OTP
- Dashboard KPI & charts
- POS catalog, shift, held, transaction, void, receipt
- Inventory products & stock movements
- Members, points, wallet
- QR menu public API
- Reservations, delivery status
- CRM tickets & FAQ
- FCM token registration