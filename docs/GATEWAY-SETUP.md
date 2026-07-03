# Setup Gateway — Payment, Email, WhatsApp

Panduan cepat konfigurasi ketiga gateway di CreativePOS.

Tutorial lengkap: [TUTORIAL-LENGKAP.md](./TUTORIAL-LENGKAP.md) bagian 6 & 8.

---

## Payment Gateway (SaaS Billing)

**Untuk:** bayar invoice langganan CreativePOS (bukan transaksi POS harian).

| Provider | Metode | Config |
|----------|--------|--------|
| **Midtrans** | VA, QRIS, GoPay, OVO, DANA | `backend/.env` |
| **Xendit** | Kartu kredit, recurring | `backend/.env` |

```env
MIDTRANS_SERVER_KEY=SB-Mid-server-xxx
MIDTRANS_CLIENT_KEY=SB-Mid-client-xxx
MIDTRANS_IS_PRODUCTION=false

XENDIT_SECRET_KEY=xnd_development_xxx
XENDIT_WEBHOOK_TOKEN=token_webhook

APP_URL=http://IP-SERVER-ANDA
```

**Webhook:**

- Midtrans: `{APP_URL}/api/v1/webhooks/payment/midtrans`
- Xendit: `{APP_URL}/api/v1/webhooks/payment/xendit`

**Uji:** Pengaturan → Langganan → Bayar invoice.

**POS harian:** Pengaturan → Bisnis → centang metode bayar (Cash, QRIS, dll.)

---

## Email Gateway (SMTP)

**Untuk:** welcome email, OTP, reset password, notifikasi login.

**Config:** Pengaturan → Integrasi → Gateway Email (per tenant).

| Field Gmail | Nilai |
|-------------|-------|
| Host | `smtp.gmail.com` |
| Port | `587` |
| Enkripsi | TLS |
| Password | App Password (bukan password login) |

**Dev tanpa SMTP:** `MAIL_MAILER=log` di `backend/.env`

**API:**

- `PUT /api/v1/settings/integrations/email`
- `POST /api/v1/settings/integrations/email/test`

---

## WhatsApp Gateway

**Untuk:** OTP, notifikasi pelanggan, CRM.

**Config:** Pengaturan → Integrasi → WhatsApp (per tenant).

| Provider | Cara |
|----------|------|
| **Fonnte** | Daftar fonnte.com → scan QR → salin API Token |
| **Wablas** | API URL + token dari dashboard |
| **Meta** | WhatsApp Business API token |

Nomor pengirim: `628xxxxxxxxxx` (tanpa `+`).

**API:**

- `PUT /api/v1/settings/integrations/whatsapp`
- `POST /api/v1/settings/integrations/whatsapp/test`

---

## Setelah ubah `.env` (payment)

```bash
docker compose -f docker-compose.client.yml exec backend php artisan config:clear
docker compose -f docker-compose.client.yml exec backend php artisan config:cache
docker compose -f docker-compose.client.yml restart backend
```

Production: webhook payment **wajib HTTPS** + `APP_URL` publik.