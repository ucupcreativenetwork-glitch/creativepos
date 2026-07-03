# TAHAP 1 — Feature List Lengkap

## CreativePOS Feature Matrix

**Total Fitur:** 280+  
**Kategori:** 16 modul

---

## M00 — Platform Management (Super Admin)

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M00-F01 | Tenant List | Lihat seluruh tenant dengan filter & search | Platform |
| M00-F02 | Create Tenant | Onboard tenant baru dengan owner account | Platform |
| M00-F03 | Edit Tenant | Update profil tenant | Platform |
| M00-F04 | Suspend Tenant | Nonaktifkan akses tenant | Platform |
| M00-F05 | Activate Tenant | Aktifkan kembali tenant | Platform |
| M00-F06 | Delete Tenant | Soft delete tenant & data | Platform |
| M00-F07 | Package CRUD | Kelola paket langganan | Platform |
| M00-F08 | Feature Toggle per Package | Enable/disable fitur per paket | Platform |
| M00-F09 | Subscription List | Lihat semua subscription | Platform |
| M00-F10 | Subscription Create | Buat subscription manual | Platform |
| M00-F11 | Subscription Renew | Perpanjang langganan | Platform |
| M00-F12 | Subscription Upgrade/Downgrade | Ubah paket tenant | Platform |
| M00-F13 | Billing Invoice | Generate invoice langganan | Platform |
| M00-F14 | Payment History | Riwayat pembayaran tenant | Platform |
| M00-F15 | Platform Dashboard | MRR, churn, active tenants | Platform |
| M00-F16 | System Health Monitor | CPU, memory, queue status | Platform |
| M00-F17 | Maintenance Mode | Global maintenance toggle | Platform |
| M00-F18 | Impersonate Tenant | Login as tenant owner (audit) | Platform |

---

## M01 — Authentication & Authorization

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M01-F01 | Email Login | Login dengan email & password | All |
| M01-F02 | Tenant Registration | Register bisnis baru + owner | All |
| M01-F03 | Forgot Password | Request reset link via email | All |
| M01-F04 | Reset Password | Set password baru via token | All |
| M01-F05 | Email Verification | Verify email setelah register | All |
| M01-F06 | OTP Email | 6-digit OTP via email | All |
| M01-F07 | OTP WhatsApp | 6-digit OTP via WhatsApp | Business+ |
| M01-F08 | Google Login | OAuth 2.0 Google sign-in | All |
| M01-F09 | Two Factor Auth (2FA) | TOTP authenticator app | All |
| M01-F10 | Enable/Disable 2FA | User manage 2FA settings | All |
| M01-F11 | Recovery Codes | Backup codes untuk 2FA | All |
| M01-F12 | Session List | Lihat active sessions | All |
| M01-F13 | Revoke Session | Logout dari device tertentu | All |
| M01-F14 | Device List | Trusted devices management | All |
| M01-F15 | Remove Device | Hapus trusted device | All |
| M01-F16 | Role Management | CRUD roles (Spatie) | Owner |
| M01-F17 | Permission Management | CRUD permissions | Owner |
| M01-F18 | Assign Role to User | Role assignment per user | Owner |
| M01-F19 | Assign Permission to Role | Permission assignment | Owner |
| M01-F20 | Login History | IP, device, browser, timestamp | All |
| M01-F21 | Change Password | User change own password | All |
| M01-F22 | API Token Management | Sanctum personal access tokens | Professional+ |
| M01-F23 | Rate Limit Login | Brute force protection | All |
| M01-F24 | Account Lockout | Lock after N failed attempts | All |

### Roles (10)

| Role | Scope |
|------|-------|
| Super Admin | Platform-wide |
| Owner | Full tenant access |
| Manager | Outlet management |
| Supervisor | Shift oversight |
| Cashier | POS transactions |
| Waiter | Table orders |
| Kitchen | KDS only |
| Driver | Delivery only |
| Customer Service | CRM only |
| Customer | Member portal |

---

## M02 — Dashboard

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M02-F01 | Revenue Today | Total penjualan hari ini | All |
| M02-F02 | Revenue This Week | Total penjualan minggu ini | All |
| M02-F03 | Revenue This Month | Total penjualan bulan ini | All |
| M02-F04 | Revenue This Year | Total penjualan tahun ini | Business+ |
| M02-F05 | Best Selling Product | Top 10 produk terlaris | All |
| M02-F06 | Outlet Performance | Perbandingan performa outlet | Business+ |
| M02-F07 | New Members | Member baru periode ini | Business+ |
| M02-F08 | Active Reservations | Reservasi aktif hari ini | Business+ |
| M02-F09 | Active Deliveries | Delivery sedang berjalan | Professional+ |
| M02-F10 | Open Tickets | Tiket CRM terbuka | Professional+ |
| M02-F11 | Stock Alerts | Produk stok menipis | All |
| M02-F12 | Cash Flow Summary | Arus kas ringkas | Business+ |
| M02-F13 | Profit Loss Summary | Ringkasan P&L | Business+ |
| M02-F14 | Sales Chart | Grafik penjualan (line/bar) | All |
| M02-F15 | Customer Growth Chart | Grafik pertumbuhan pelanggan | Business+ |
| M02-F16 | Product Performance Chart | Grafik performa produk | Business+ |
| M02-F17 | Revenue Trend Chart | Trend revenue multi-periode | Business+ |
| M02-F18 | Real-time Transaction Feed | Live feed transaksi | Business+ |
| M02-F19 | Outlet Filter | Filter dashboard per outlet | Business+ |
| M02-F20 | Date Range Filter | Custom date range | All |
| M02-F21 | Export Dashboard PDF | Export snapshot dashboard | Professional+ |
| M02-F22 | Widget Customization | Drag & arrange widgets | Enterprise |

---

## M03 — Point of Sale

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M03-F01 | Quick Sale | Tambah produk ke cart cepat | All |
| M03-F02 | Barcode Scanner | Scan barcode produk | All |
| M03-F03 | QR Scanner | Scan QR produk | All |
| M03-F04 | Product Search | Search by name/SKU/barcode | All |
| M03-F05 | Hold Transaction | Simpan transaksi sementara | All |
| M03-F06 | Resume Transaction | Lanjutkan transaksi hold | All |
| M03-F07 | Split Bill | Bagi tagihan per item/qty | Business+ |
| M03-F08 | Merge Bill | Gabung multiple bill | Business+ |
| M03-F09 | Apply Discount (%) | Diskon persentase | All |
| M03-F10 | Apply Discount (Nominal) | Diskon nominal tetap | All |
| M03-F11 | Apply Voucher | Redeem voucher code | Business+ |
| M03-F12 | Apply Promo | Auto-apply promo rules | Business+ |
| M03-F13 | Payment Cash | Bayar tunai + kembalian | All |
| M03-F14 | Payment Transfer | Bayar transfer bank | All |
| M03-F15 | Payment QRIS | Bayar via QRIS | All |
| M03-F16 | Payment Debit Card | Bayar kartu debit | Business+ |
| M03-F17 | Payment Credit Card | Bayar kartu kredit | Business+ |
| M03-F18 | Payment E-Wallet | GoPay, OVO, DANA, dll | Business+ |
| M03-F19 | Payment Wallet | Bayar via member wallet | Professional+ |
| M03-F20 | Split Payment | Multi metode bayar | Business+ |
| M03-F21 | Refund (Full) | Refund penuh | All |
| M03-F22 | Refund (Partial) | Refund sebagian | All |
| M03-F23 | Return Product | Retur barang | All |
| M03-F24 | Void Transaction | Batalkan transaksi | All |
| M03-F25 | Void Approval | Supervisor approval untuk void | All |
| M03-F26 | Print Receipt 58mm | Cetak struk thermal 58mm | All |
| M03-F27 | Print Receipt 80mm | Cetak struk thermal 80mm | All |
| M03-F28 | Reprint Receipt | Cetak ulang struk | All |
| M03-F29 | Email Receipt | Kirim struk via email | Business+ |
| M03-F30 | WhatsApp Receipt | Kirim struk via WA | Business+ |
| M03-F31 | Open Shift | Buka shift kasir | All |
| M03-F32 | Close Shift | Tutup shift + rekonsiliasi | All |
| M03-F33 | Cash Drawer Management | Cash in/out drawer | All |
| M03-F34 | Table Assignment | Assign order ke meja | Business+ |
| M03-F35 | Dine-in Order | Order untuk makan di tempat | Business+ |
| M03-F36 | Takeaway Order | Order bungkus | All |
| M03-F37 | Member Scan | Scan member QR/barcode | Business+ |
| M03-F38 | Earn Points | Auto earn loyalty points | Business+ |
| M03-F39 | Redeem Points | Tukar poin di POS | Business+ |
| M03-F40 | Tax Calculation | PPN & service charge | All |
| M03-F41 | Service Charge | Biaya layanan configurable | All |
| M03-F42 | Order Notes | Catatan khusus per item/order | All |
| M03-F43 | Kitchen Send | Kirim order ke KDS | Business+ |
| M03-F44 | POS Offline Mode | Transaksi saat offline (PWA) | Professional+ |
| M03-F45 | Keyboard Shortcuts | Hotkeys untuk cashier | All |

---

## M04 — Inventory

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M04-F01 | Category CRUD | Kelola kategori produk | All |
| M04-F02 | Sub Category CRUD | Kelola sub kategori | All |
| M04-F03 | Brand CRUD | Kelola brand/merek | All |
| M04-F04 | Product CRUD | Kelola produk utama | All |
| M04-F05 | SKU Management | Auto/manual SKU generation | All |
| M04-F06 | Barcode Generation | Generate barcode EAN-13/Code128 | All |
| M04-F07 | Product Variant | Size, warna, custom variant | All |
| M04-F08 | Variant Pricing | Harga per variant | All |
| M04-F09 | Bundle Product | Produk paket/combo | Business+ |
| M04-F10 | Bundle Pricing | Harga bundle (discount) | Business+ |
| M04-F11 | Product Image | Upload multiple images | All |
| M04-F12 | Product Description | Rich text description | All |
| M04-F13 | Stock In | Tambah stok (manual) | All |
| M04-F14 | Stock Out | Kurangi stok (manual) | All |
| M04-F15 | Stock Transfer | Transfer antar warehouse/outlet | Business+ |
| M04-F16 | Stock Adjustment | Koreksi stok | All |
| M04-F17 | Stock Opname | Physical count & reconcile | Business+ |
| M04-F18 | Opname Report | Variance report | Business+ |
| M04-F19 | Low Stock Alert | Notifikasi stok minimum | All |
| M04-F20 | Expiry Alert | Notifikasi produk kadaluarsa | Business+ |
| M04-F21 | Supplier CRUD | Kelola data supplier | Business+ |
| M04-F22 | Purchase Order Create | Buat PO | Business+ |
| M04-F23 | Purchase Order Approve | Approval workflow PO | Business+ |
| M04-F24 | Purchase Order Cancel | Batalkan PO | Business+ |
| M04-F25 | Goods Receipt (GRN) | Terima barang dari PO | Business+ |
| M04-F26 | Purchase Return | Retur ke supplier | Business+ |
| M04-F27 | Warehouse CRUD | Kelola gudang | Business+ |
| M04-F28 | Outlet Stock View | Stok per outlet | All |
| M04-F29 | Stock Movement History | Riwayat pergerakan stok | All |
| M04-F30 | Cost Price Tracking | HPP/average cost | Business+ |
| M04-F31 | Product Import CSV | Bulk import produk | Business+ |
| M04-F32 | Product Export CSV | Export data produk | All |
| M04-F33 | Barcode Label Print | Cetak label barcode | All |
| M04-F34 | Unit of Measure | PCS, KG, LITER, dll | All |
| M04-F35 | Product Archive | Soft delete/archive produk | All |

---

## M05 — Loyalty & Member

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M05-F01 | Member Register (Manual) | Daftar member oleh staff | Business+ |
| M05-F02 | Member Self Register | Daftar mandiri via portal | Business+ |
| M05-F03 | Member Code Generation | Auto generate member code | Business+ |
| M05-F04 | Member QR Code | QR code unik per member | Business+ |
| M05-F05 | Member Barcode | Barcode unik per member | Business+ |
| M05-F06 | Member Profile Edit | Update data member | Business+ |
| M05-F07 | Member Search | Search by code/name/phone | Business+ |
| M05-F08 | Point Config | Set earn rate (e.g. Rp10k=1pt) | Business+ |
| M05-F09 | Point Earn (Auto) | Auto earn dari transaksi POS | Business+ |
| M05-F10 | Point Redeem | Tukar poin jadi diskon | Business+ |
| M05-F11 | Point Expiry | Poin kadaluarsa configurable | Professional+ |
| M05-F12 | Point History | Riwayat earn/redeem | Business+ |
| M05-F13 | Tier Bronze | Level membership bronze | Business+ |
| M05-F14 | Tier Silver | Level membership silver | Business+ |
| M05-F15 | Tier Gold | Level membership gold | Business+ |
| M05-F16 | Tier Platinum | Level membership platinum | Business+ |
| M05-F17 | Tier Auto Upgrade | Auto naik tier berdasarkan spend | Business+ |
| M05-F18 | Voucher Reward | Reward berupa voucher | Business+ |
| M05-F19 | Cashback Reward | Reward berupa cashback | Professional+ |
| M05-F20 | Product Reward | Reward berupa produk gratis | Business+ |
| M05-F21 | Birthday Reward | Auto reward di hari ulang tahun | Business+ |
| M05-F22 | Referral Code | Generate kode referral | Professional+ |
| M05-F23 | Referral Reward | Reward untuk referrer & referee | Professional+ |
| M05-F24 | Member Portal | Portal self-service member | Business+ |
| M05-F25 | Member Deactivate | Nonaktifkan member | Business+ |

---

## M06 — Member Wallet

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M06-F01 | Wallet Balance View | Lihat saldo wallet | Professional+ |
| M06-F02 | Top Up (Cash) | Isi saldo via kasir | Professional+ |
| M06-F03 | Top Up (Transfer) | Isi saldo via transfer | Professional+ |
| M06-F04 | Top Up (Payment Gateway) | Isi saldo online | Professional+ |
| M06-F05 | Withdraw Request | Ajukan penarikan saldo | Professional+ |
| M06-F06 | Withdraw Approve | Approval penarikan | Professional+ |
| M06-F07 | Transfer to Member | Transfer antar member | Professional+ |
| M06-F08 | Wallet Payment POS | Bayar pakai wallet di POS | Professional+ |
| M06-F09 | Wallet History | Riwayat semua transaksi wallet | Professional+ |
| M06-F10 | Wallet Limit Config | Set min/max saldo | Professional+ |
| M06-F11 | Wallet Statement | Statement periodik | Professional+ |

---

## M07 — QR Digital Menu

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M07-F01 | Table QR Generate | Generate QR per meja | Business+ |
| M07-F02 | Table QR Print | Cetak QR meja | Business+ |
| M07-F03 | Menu Category Display | Tampilkan kategori menu | Business+ |
| M07-F04 | Menu Product Display | Tampilkan produk + foto | Business+ |
| M07-F05 | Product Availability | Status tersedia/habis | Business+ |
| M07-F06 | Guest Browse Menu | Lihat menu tanpa login | Business+ |
| M07-F07 | Guest Add to Cart | Tambah ke keranjang | Business+ |
| M07-F08 | Guest Checkout | Order tanpa akun | Business+ |
| M07-F09 | Member Login Menu | Login member di menu | Business+ |
| M07-F10 | Member Checkout | Order dengan akun member | Business+ |
| M07-F11 | Order to Kitchen | Kirim order ke KDS | Business+ |
| M07-F12 | Order to POS | Muncul di POS sebagai order | Business+ |
| M07-F13 | Menu Branding | Logo & warna tenant | Business+ |
| M07-F14 | Call Waiter | Panggil pelayan dari menu | Business+ |
| M07-F15 | Request Bill | Minta bill dari menu | Business+ |

---

## M08 — Kitchen Display System

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M08-F01 | Order Queue Display | Tampilan antrian order | Business+ |
| M08-F02 | Real-time Update (WS) | Update via WebSocket | Business+ |
| M08-F03 | Status: Pending | Order baru masuk | Business+ |
| M08-F04 | Status: Cooking | Sedang dimasak | Business+ |
| M08-F05 | Status: Ready | Siap disajikan | Business+ |
| M08-F06 | Status: Served | Sudah disajikan | Business+ |
| M08-F07 | Station Filter | Filter per station dapur | Business+ |
| M08-F08 | Order Timer | Waktu elapsed per order | Business+ |
| M08-F09 | Bump Complete | Tandai selesai (bump) | Business+ |
| M08-F10 | Sound Alert | Suara notifikasi order baru | Business+ |
| M08-F11 | Order Priority | Prioritas order (VIP, urgent) | Professional+ |
| M08-F12 | Multi Screen | Multiple KDS screen support | Professional+ |

---

## M09 — Reservation

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M09-F01 | Create Reservation | Buat reservasi baru | Business+ |
| M09-F02 | Edit Reservation | Ubah detail reservasi | Business+ |
| M09-F03 | Cancel Reservation | Batalkan reservasi | Business+ |
| M09-F04 | Reservation Calendar | Kalender visual | Business+ |
| M09-F05 | Time Slot Management | Kelola slot waktu | Business+ |
| M09-F06 | Table Assignment | Assign meja ke reservasi | Business+ |
| M09-F07 | Status: Pending | Menunggu konfirmasi | Business+ |
| M09-F08 | Status: Confirmed | Dikonfirmasi | Business+ |
| M09-F09 | Status: Arrived | Tamu sudah datang | Business+ |
| M09-F10 | Status: Completed | Selesai | Business+ |
| M09-F11 | Status: Cancelled | Dibatalkan | Business+ |
| M09-F12 | WhatsApp Reminder | Reminder H-1 & H-0 | Business+ |
| M09-F13 | Email Reminder | Reminder via email | Business+ |
| M09-F14 | Walk-in Convert | Ubah walk-in jadi reservasi | Business+ |
| M09-F15 | No-show Auto Cancel | Auto cancel jika no-show | Professional+ |
| M09-F16 | Online Reservation | Reservasi via website/portal | Business+ |
| M09-F17 | Guest Count Validation | Validasi kapasitas meja | Business+ |

---

## M10 — Delivery

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M10-F01 | Create Delivery Order | Buat order delivery | Professional+ |
| M10-F02 | Status: Waiting | Menunggu konfirmasi | Professional+ |
| M10-F03 | Status: Processing | Sedang diproses | Professional+ |
| M10-F04 | Status: Cooking | Sedang dimasak | Professional+ |
| M10-F05 | Status: Ready | Siap diantar | Professional+ |
| M10-F06 | Status: Delivering | Sedang dalam perjalanan | Professional+ |
| M10-F07 | Status: Completed | Selesai diantar | Professional+ |
| M10-F08 | Internal Driver Assign | Assign driver internal | Professional+ |
| M10-F09 | External Driver Assign | Assign driver eksternal | Professional+ |
| M10-F10 | Driver App View | Tampilan khusus driver | Professional+ |
| M10-F11 | Multiple Address | Simpan banyak alamat | Professional+ |
| M10-F12 | GPS Coordinate | Koordinat GPS alamat | Professional+ |
| M10-F13 | GPS Tracking | Lacak posisi driver real-time | Professional+ |
| M10-F14 | Flat Shipping Fee | Ongkir flat rate | Professional+ |
| M10-F15 | Distance-based Fee | Ongkir berdasarkan jarak | Professional+ |
| M10-F16 | Delivery Zone Config | Area pengantaran | Professional+ |
| M10-F17 | Google Maps Integration | Maps & routing | Professional+ |
| M10-F18 | OpenStreetMap Integration | Alternative maps | Professional+ |
| M10-F19 | Delivery ETA | Estimasi waktu tiba | Professional+ |
| M10-F20 | Delivery Proof | Foto bukti pengantaran | Professional+ |
| M10-F21 | Customer Tracking Page | Halaman lacak pesanan | Professional+ |

---

## M11 — CRM

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M11-F01 | Create Ticket | Buat tiket baru | Professional+ |
| M11-F02 | Ticket Number Auto | Auto generate nomor tiket | Professional+ |
| M11-F03 | Priority: Low/Medium/High/Critical | Set prioritas | Professional+ |
| M11-F04 | Assign Agent | Assign ke CS agent | Professional+ |
| M11-F05 | SLA Timer | Countdown SLA | Professional+ |
| M11-F06 | Channel: WhatsApp | Tiket dari WhatsApp | Professional+ |
| M11-F07 | Channel: Telegram | Tiket dari Telegram | Professional+ |
| M11-F08 | Channel: Email | Tiket dari email | Professional+ |
| M11-F09 | Channel: Website | Tiket dari web form | Professional+ |
| M11-F10 | Status: Open/Assigned/Pending/Resolved/Closed | Flow status | Professional+ |
| M11-F11 | Internal Notes | Catatan internal agent | Professional+ |
| M11-F12 | Customer Reply | Balasan ke customer | Professional+ |
| M11-F13 | FAQ Management | Kelola FAQ | Professional+ |
| M11-F14 | Documentation | Artikel dokumentasi | Professional+ |
| M11-F15 | Tutorials | Video/text tutorial | Professional+ |
| M11-F16 | Customer Rating 1-5 | Rating layanan | Professional+ |
| M11-F17 | Canned Responses | Template balasan cepat | Professional+ |
| M11-F18 | Agent Performance Report | Metrik kinerja agent | Professional+ |
| M11-F19 | Ticket Escalation | Eskalasi otomatis | Enterprise |
| M11-F20 | CSAT Survey | Survey kepuasan | Professional+ |

---

## M12 — WhatsApp Integration

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M12-F01 | OTP via WhatsApp | Kirim OTP login/register | Business+ |
| M12-F02 | Invoice Notification | Kirim invoice transaksi | Business+ |
| M12-F03 | Payment Notification | Notifikasi pembayaran | Business+ |
| M12-F04 | Reservation Reminder | Reminder reservasi | Business+ |
| M12-F05 | Loyalty Notification | Notifikasi poin & tier | Business+ |
| M12-F06 | Promo Broadcast | Broadcast promo massal | Professional+ |
| M12-F07 | Template Management | Kelola template pesan | Business+ |
| M12-F08 | Webhook Handler | Terima pesan masuk | Professional+ |
| M12-F09 | Delivery Status Update | Update status delivery via WA | Professional+ |
| M12-F10 | Two-way Chat | Balas pesan customer | Enterprise |

---

## M13 — Reporting

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M13-F01 | Sales Daily Report | Laporan penjualan harian | All |
| M13-F02 | Sales Weekly Report | Laporan mingguan | All |
| M13-F03 | Sales Monthly Report | Laporan bulanan | All |
| M13-F04 | Sales Yearly Report | Laporan tahunan | Business+ |
| M13-F05 | Product Sales Report | Penjualan per produk | All |
| M13-F06 | Customer Activity Report | Aktivitas pelanggan | Business+ |
| M13-F07 | Member Growth Report | Pertumbuhan member | Business+ |
| M13-F08 | Inventory Movement Report | Pergerakan stok | Business+ |
| M13-F09 | Purchase Report | Laporan pembelian | Business+ |
| M13-F10 | Profit Loss Report | Laporan laba rugi | Business+ |
| M13-F11 | Cash Flow Report | Laporan arus kas | Business+ |
| M13-F12 | Export PDF | Export ke PDF | All |
| M13-F13 | Export Excel | Export ke Excel | All |
| M13-F14 | Export CSV | Export ke CSV | All |
| M13-F15 | Scheduled Report Email | Kirim laporan otomatis | Professional+ |
| M13-F16 | Custom Report Builder | Buat laporan custom | Enterprise |
| M13-F17 | Shift Report | Laporan per shift kasir | All |
| M13-F18 | Tax Report | Laporan pajak (PPN) | Business+ |
| M13-F19 | Void/Refund Report | Laporan void & refund | All |
| M13-F20 | Comparison Report | Perbandingan periode | Business+ |

---

## M14 — Settings

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M14-F01 | Tenant Profile | Nama bisnis, logo, alamat | All |
| M14-F02 | Outlet CRUD | Kelola outlet/cabang | All |
| M14-F03 | Tax Config (PPN) | Konfigurasi PPN | All |
| M14-F04 | Service Charge Config | Biaya layanan | All |
| M14-F05 | Payment Method Toggle | Enable/disable metode bayar | All |
| M14-F06 | Printer Config | Setting printer per outlet | All |
| M14-F07 | Notification Preferences | Preferensi notifikasi | All |
| M14-F08 | Business Hours | Jam operasional | All |
| M14-F09 | Receipt Template | Template struk custom | Business+ |
| M14-F10 | Payment Gateway Config | API key payment gateway | Business+ |
| M14-F11 | WhatsApp API Config | API key WhatsApp | Business+ |
| M14-F12 | Maps API Config | Google Maps API key | Professional+ |
| M14-F13 | Currency & Locale | Mata uang & locale | All |
| M14-F14 | Timezone Config | Zona waktu tenant | All |

---

## M15 — Audit & Security

| # | Feature | Description | Package |
|---|---------|-------------|---------|
| M15-F01 | Audit Log (CRUD) | Log semua operasi data | All |
| M15-F02 | Activity Log | Log aktivitas user | All |
| M15-F03 | Login History | Riwayat login | All |
| M15-F04 | Device Tracking | Lacak device terdaftar | All |
| M15-F05 | Rate Limiting Config | Konfigurasi rate limit | Owner |
| M15-F06 | IP Whitelist | Batasi akses by IP | Enterprise |
| M15-F07 | Data Export (GDPR) | Export data user | All |
| M15-F08 | Data Deletion Request | Hapus data user | All |
| M15-F09 | Security Dashboard | Overview keamanan | Owner |
| M15-F10 | Failed Login Alert | Alert login gagal berulang | All |