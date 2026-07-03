# Deploy Ubuntu + Cloudflare (Akses dari Mana Saja)

Panduan memasang CreativePOS di VPS Ubuntu dan mengaksesnya lewat domain Cloudflare — web & aplikasi mobile.

**Contoh domain:** `pos.creativenetwork.id`  
**Repo:** https://github.com/ucupcreativenetwork-glitch/creativepos

---

## Ringkasan arsitektur

```
HP / Browser (internet)
        ↓ HTTPS
   Cloudflare (SSL + CDN)
        ↓ HTTP port 80
   VPS Ubuntu (Docker + Nginx)
        ↓
   Frontend + Backend + MySQL
```

---

## Bagian 1 — Siapkan VPS Ubuntu

### Spesifikasi minimal

| Item | Nilai |
|------|-------|
| OS | Ubuntu 22.04 / 24.04 LTS |
| RAM | 4 GB |
| CPU | 2 core |
| Disk | 20 GB |
| Port terbuka | 22, 80, 443 |

### Install CreativePOS (satu baris)

SSH ke VPS, lalu:

```bash
curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash
```

Atau clone manual:

```bash
sudo git clone https://github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
cd /opt/creativepos
sudo bash install.sh
```

Catat **IP publik VPS** (mis. `203.0.113.50`).

Cek instalasi:

```bash
curl -s http://IP-VPS/api/v1/health
# harus: "success": true
```

---

## Bagian 2 — Setup Cloudflare

### 2.1 Tambah domain di Cloudflare

1. Login [dash.cloudflare.com](https://dash.cloudflare.com)
2. **Add a Site** → masukkan domain Anda
3. Ikuti wizard — ganti nameserver domain ke Cloudflare (di registrar domain)

### 2.2 DNS Record

Di Cloudflare → **DNS** → **Records**:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `pos` | `IP-VPS-ANDA` | **Proxied** (ikon awan oranye) |

Hasil: `https://pos.domain-anda.com` → VPS Anda.

> Bisa juga pakai root `@` jika seluruh domain untuk POS.

### 2.3 SSL/TLS (paling mudah: Flexible)

Cloudflare → **SSL/TLS** → **Overview**:

- Pilih **Flexible**
  - Pengunjung: HTTPS (Cloudflare)
  - Server Ubuntu: HTTP port 80 (sudah didukung install default)

> Nanti bisa upgrade ke **Full (strict)** + Origin Certificate jika perlu.

### 2.4 Aturan cache API (penting!)

Cloudflare → **Rules** → **Page Rules** (atau Cache Rules):

Buat rule **Bypass cache** untuk:

- `*pos.domain-anda.com/api/*`
- `*pos.domain-anda.com/login*`

Tanpa ini, login/API bisa error karena response di-cache.

### 2.5 WebSocket (opsional, untuk fitur real-time)

Cloudflare → **Network** → aktifkan **WebSockets**

---

## Bagian 3 — Konfigurasi domain di server

Setelah DNS aktif, jalankan di VPS:

```bash
cd /opt/creativepos
sudo bash scripts/configure-domain.sh pos.domain-anda.com
```

Skrip ini mengatur:

- `APP_URL=https://pos.domain-anda.com`
- `FRONTEND_URL`, `SANCTUM_STATEFUL_DOMAINS`, `REVERB_*`
- Rebuild container + clear cache

Atau manual edit `backend/.env`:

```env
APP_URL=https://pos.domain-anda.com
FRONTEND_URL=https://pos.domain-anda.com
SANCTUM_STATEFUL_DOMAINS=pos.domain-anda.com,localhost,127.0.0.1
REVERB_HOST=pos.domain-anda.com
REVERB_SCHEME=https
REVERB_PORT=443
TRUSTED_PROXIES=*
```

Lalu:

```bash
cd /opt/creativepos/docker
docker compose -f docker-compose.client.yml exec -T backend php artisan config:cache
docker compose -f docker-compose.client.yml restart nginx backend frontend
```

---

## Bagian 4 — Aplikasi mobile (HP)

### Pertama kali setup server di HP

1. Buka aplikasi CreativePOS
2. Layar **Setup Server** → masukkan:

   ```
   https://pos.domain-anda.com
   ```

   (wajib pakai `https://`, tanpa `/api`)

3. Tap **Hubungkan** → login seperti biasa

### Update APK setelah deploy baru

- Upload APK di **Platform Admin** → `https://pos.domain-anda.com/platform`
- HP akan cek OTA otomatis dari domain yang sama

### Jika HP sudah pernah pakai IP lokal

1. Buka **Pengaturan** → ganti alamat server ke domain HTTPS baru
2. Atau hapus data app → setup ulang dengan domain

---

## Bagian 5 — Verifikasi

| Cek | Perintah / URL |
|-----|----------------|
| Health API | `https://pos.domain-anda.com/api/v1/health` |
| Login web | `https://pos.domain-anda.com/login` |
| Super Admin | `superadmin@creativepos.local` / `SuperAdmin123!` |
| Remote devices | `https://pos.domain-anda.com/platform/devices` |

```bash
# Dari VPS
curl -s https://pos.domain-anda.com/api/v1/health
```

---

## Update ke versi terbaru

```bash
cd /opt/creativepos
sudo bash update.sh
sudo bash scripts/configure-domain.sh pos.domain-anda.com
```

---

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Web bisa dibuka tapi login gagal | Bypass cache untuk `/api/*` di Cloudflare |
| Redirect loop HTTPS | SSL mode = **Flexible** (origin masih HTTP) |
| Mobile "tidak bisa hubung server" | Pastikan URL `https://domain` tanpa port |
| IP salah di Remote Device Center | Sudah diperbaiki dengan `TRUSTED_PROXIES=*` |
| Error 522 / timeout | Cek firewall VPS: `sudo ufw allow 80` |
| Mixed content di web | Rebuild frontend setelah set domain HTTPS |

---

## Keamanan (disarankan)

1. Ganti password default setelah login pertama
2. Cloudflare → **Security** → aktifkan **Bot Fight Mode** (opsional)
3. Cloudflare → **Access** → batasi `/platform` hanya IP kantor (opsional)
4. Backup database rutin: `bash /opt/creativepos/docker/scripts/backup-db.sh`