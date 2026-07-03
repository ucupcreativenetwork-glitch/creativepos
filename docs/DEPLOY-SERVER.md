# Deploy / Update Server CreativePOS

Panduan singkat deploy dan update dari GitHub ke server Anda.

**Repo:** https://github.com/ucupcreativenetwork-glitch/creativepos  
**Branch:** `main`

---

## Instal baru (server kosong)

### Ubuntu / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash
# atau dengan IP manual:
curl -fsSL https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.sh | sudo bash -s -- 10.110.1.15
```

### Windows Server

```powershell
# PowerShell sebagai Administrator
irm https://raw.githubusercontent.com/ucupcreativenetwork-glitch/creativepos/main/bootstrap.ps1 | iex
```

---

## Update server (sudah terinstall)

### Linux (Docker)

```bash
cd /opt/creativepos
sudo bash update.sh
```

### Windows (Docker)

```powershell
cd D:\creativepos
powershell -ExecutionPolicy Bypass -File update.ps1
```

Skrip update otomatis:
1. `git pull` dari GitHub
2. Rebuild container Docker
3. `php artisan migrate --force`
4. Cache config & route
5. Unduh APK terbaru (jika ada di GitHub Releases)

---

## Update komputer development (lokal)

Tanpa Docker — untuk setup XAMPP + `php artisan serve` + `npm run dev`:

```powershell
cd D:\pos
powershell -ExecutionPolicy Bypass -File scripts\update-dev.ps1
```

---

## URL setelah deploy

| Layanan | URL |
|---------|-----|
| Web login | `http://IP-SERVER/login` |
| Dashboard | `http://IP-SERVER/dashboard` |
| Platform Admin | `http://IP-SERVER/platform` |
| Remote Device Center | `http://IP-SERVER/platform/devices` |
| API health | `http://IP-SERVER/api/v1/health` |
| OTA mobile | `http://IP-SERVER/api/v1/mobile/version?platform=android` |

## Akun default

| Role | Email | Password |
|------|-------|----------|
| Admin Toko | `admin@creativepos.local` | `Admin123!` |
| Super Admin | `superadmin@creativepos.local` | `SuperAdmin123!` |

---

## Fitur terbaru (v1.4.0)

- Login web diperbaiki (cookie token Sanctum)
- Remote Agent di HP & Web (heartbeat + perintah diagnostik)
- Dashboard **Remote Device Center** — pantau IP, device ID, kirim perintah remote
- Hydration error dashboard diperbaiki

---

## Repo private

```bash
export GITHUB_TOKEN=ghp_xxxxxxxx
git clone https://${GITHUB_TOKEN}@github.com/ucupcreativenetwork-glitch/creativepos.git /opt/creativepos
```

---

## Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Login web gagal | Hard refresh `Ctrl+Shift+R`, pastikan akses via IP server bukan localhost |
| Perangkat tidak muncul di Remote Center | Login dulu di HP/Web, tunggu 1–2 menit |
| Migrate error | `php artisan migrate --force` manual di container backend |
| APK tidak update | Build APK baru lalu publish via Platform Admin → Upload APK |

Panduan lengkap: [CLIENT-INSTALL.md](./CLIENT-INSTALL.md)