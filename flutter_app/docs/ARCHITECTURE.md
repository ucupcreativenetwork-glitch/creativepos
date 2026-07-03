# CreativePOS Mobile — Arsitektur Flutter

## Pattern

```
Presentation (Views / Widgets)
        ↓
ViewModel / Providers (Riverpod)
        ↓
Repository (abstraction)
        ↓
API Service (Dio) + Local DB (Hive/SQLite)
```

- **Clean Architecture** per feature
- **MVVM** via Riverpod `StateNotifier` / `FutureProvider`
- **Offline First** — SQLite queue + auto-sync dengan idempotency key
- **No business logic** di mobile — validasi di Laravel

## Struktur Folder

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/          # AppConfig, env
│   ├── constants/       # ApiPaths
│   ├── errors/          # AppException types
│   ├── network/         # Dio, interceptors
│   ├── router/          # GoRouter
│   ├── storage/         # Secure storage keys
│   ├── theme/           # Material 3
│   └── utils/           # Formatters
├── shared/
│   ├── models/          # ApiResponse, Pagination
│   └── widgets/         # Reusable UI
├── features/
│   ├── auth/            # Login, 2FA, server setup
│   ├── dashboard/       # KPI, charts
│   ├── pos/             # Tahap 3
│   ├── inventory/       # Tahap 3
│   ├── members/         # Tahap 4 ✅
│   ├── qr_menu/         # Tahap 4 ✅
│   ├── reservations/    # Tahap 4 ✅
│   ├── delivery/        # Tahap 5 ✅
│   ├── crm/               # Tahap 5 ✅
│   ├── notifications/     # Tahap 5 ✅
│   ├── operations/        # Tahap 5 hub
│   ├── shell/           # Navigation shell
│   └── settings/
├── repositories/        # (per feature, co-located)
├── services/            # Biometric, FCM, printer
└── local_database/      # SQLite offline queue ✅
```

## Navigasi

| Route | Screen | Auth |
|-------|--------|------|
| `/server-setup` | Server URL | No |
| `/login` | Login | No |
| `/two-factor` | 2FA | Pending |
| `/dashboard` | Dashboard | Yes |
| `/pos` | POS | Yes |
| `/inventory` | Inventory | Yes |
| `/members` | Members | Yes |
| `/operations` | Delivery / CRM / Notifikasi | Yes |
| `/sync` | Offline queue sync | Yes |
| `/settings` | Settings | Yes |

**Adaptive layout:**
- Phone: bottom `NavigationBar`
- Tablet (≥840dp): `NavigationRail`

## Auth Flow

1. Bootstrap → baca `server_url` + `token` dari Secure Storage
2. Token ada → `GET /auth/me` (auto login)
3. Token invalid → login screen
4. Login → Sanctum Bearer token disimpan secure
5. 401 → clear token, redirect login

## API Client

- Base URL: `{server}/api/v1`
- Header: `Authorization: Bearer {token}`
- Idempotency (POS): `Idempotency-Key` header — Tahap 3

## Fase Implementasi

| Tahap | Status |
|-------|--------|
| 1 — API map + scaffold + routing | ✅ |
| 2 — Auth + Dashboard | ✅ |
| 3 — POS + Inventory | ✅ |
| 4 — Member + QR Menu + Reservasi | ✅ |
| 5 — Delivery + CRM + FCM | ✅ |
| 6 — Offline + Printer | ✅ |
| 7 — Build APK/AAB + Play Store | ✅ |

Semua 7 tahap implementasi Flutter selesai. Build: `scripts/build-flutter-android.ps1`.