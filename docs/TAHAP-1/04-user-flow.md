# TAHAP 1 — User Flow

## CreativePOS User Flow Documentation

---

## 1. Tenant Onboarding Flow (Super Admin → Owner)

```
┌─────────────┐     ┌──────────────┐     ┌───────────────┐     ┌──────────────┐
│  Super Admin │────▶│ Create Tenant│────▶│ Assign Package│────▶│ Create Owner │
│  Login       │     │ (name, slug) │     │ (Starter/etc) │     │ Account      │
└─────────────┘     └──────────────┘     └───────────────┘     └──────┬───────┘
                                                                       │
                    ┌──────────────┐     ┌───────────────┐     ┌───────▼──────┐
                    │ Setup Complete│◀────│ Initial Setup │◀────│ Send Welcome │
                    │ Dashboard     │     │ Wizard        │     │ Email        │
                    └──────────────┘     └───────────────┘     └──────────────┘
```

### Steps

1. Super Admin login ke platform dashboard
2. Klik "Create Tenant" → isi nama bisnis, slug, kontak
3. Pilih paket langganan (Starter/Business/Professional/Enterprise)
4. Sistem buat owner account + kirim email welcome
5. Owner login → Setup Wizard:
   - Step 1: Profil bisnis (logo, alamat, NPWP)
   - Step 2: Buat outlet pertama
   - Step 3: Setup kategori & produk awal
   - Step 4: Invite staff (opsional)
   - Step 5: Konfigurasi pembayaran
6. Redirect ke Dashboard

---

## 2. Authentication Flow

### 2.1 Login Flow

```
┌────────┐    ┌───────────┐    ┌────────────┐    ┌──────────┐    ┌───────────┐
│ Landing│───▶│ Login Form│───▶│ Validate   │───▶│ 2FA?     │───▶│ Dashboard │
│ Page   │    │ email+pwd │    │ Credentials│    │ Yes→TOTP │    │ (by role) │
└────────┘    └───────────┘    └────────────┘    │ No→Direct│    └───────────┘
                                                  └──────────┘
```

### 2.2 Register Flow (Self-Service)

```
┌────────┐    ┌───────────┐    ┌────────────┐    ┌─────────────┐    ┌──────────┐
│ Register│──▶│ Fill Form │──▶│ Email      │───▶│ Verify OTP  │───▶│ Setup    │
│ Page    │    │ biz+owner │    │ Verify Link│    │ (optional)  │    │ Wizard   │
└────────┘    └───────────┘    └────────────┘    └─────────────┘    └──────────┘
```

### 2.3 Forgot Password Flow

```
┌──────────┐    ┌────────────┐    ┌─────────────┐    ┌────────────┐    ┌────────┐
│ Forgot   │───▶│ Enter Email│───▶│ Send Reset  │───▶│ Click Link │───▶│ New    │
│ Password │    │            │    │ Link/OTP    │    │ in Email   │    │ Password│
└──────────┘    └────────────┘    └─────────────┘    └────────────┘    └────────┘
```

### 2.4 Google OAuth Flow

```
┌────────┐    ┌────────────┐    ┌─────────────┐    ┌──────────────┐    ┌──────────┐
│ Login  │───▶│ Google     │───▶│ OAuth       │───▶│ Account      │───▶│ Dashboard│
│ Page   │    │ Sign In Btn│    │ Callback    │    │ Link/Create  │    │          │
└────────┘    └────────────┘    └─────────────┘    └──────────────┘    └──────────┘
```

---

## 3. POS Transaction Flow (Cashier)

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Open     │───▶│ Add       │───▶│ Apply      │───▶│ Select     │───▶│ Process   │
│ Shift    │    │ Products  │    │ Discount   │    │ Payment    │    │ Payment   │
└──────────┘    │ (scan/    │    │ (optional) │    │ Method     │    └─────┬─────┘
                │  search)  │    └────────────┘    └────────────┘          │
                └───────────┘                                                │
         ┌─────────────┐    ┌────────────┐    ┌────────────┐    ┌─────────▼─────┐
         │ Stock       │◀───│ Kitchen    │◀───│ Print      │◀───│ Complete      │
         │ Deducted    │    │ Order Sent │    │ Receipt    │    │ Transaction   │
         └─────────────┘    │ (if dine-in)│    └────────────┘    └───────────────┘
                            └────────────┘
```

### POS Sub-Flows

#### Hold Transaction
```
Active Cart → Click "Hold" → Enter Reference Name → Cart Saved → New Cart Available
                                    ↓
Resume: Hold List → Select → Cart Restored → Continue
```

#### Split Bill
```
Active Cart → Click "Split" → Select Items per Bill → Generate Sub-Bills → Individual Payment
```

#### Void Transaction
```
Transaction History → Select Transaction → Click "Void" → Supervisor PIN → Void Confirmed → Stock Restored
```

#### Refund
```
Transaction History → Select Transaction → Click "Refund" → Select Items/Amount → Supervisor Approval → Refund Processed
```

---

## 4. QR Digital Menu Flow (Customer)

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Scan QR  │───▶│ View Menu │───▶│ Browse     │───▶│ Add to     │───▶│ Review    │
│ on Table │    │ (Table A01)│    │ Categories │    │ Cart       │    │ Cart      │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └─────┬─────┘
                                                                            │
                    ┌──────────┐    ┌────────────┐    ┌────────────┐  ┌─────▼─────┐
                    │ Order    │◀───│ Payment    │◀───│ Confirm    │◀─│ Checkout  │
                    │ Tracking │    │ (at table/ │    │ Order      │  │ (guest/   │
                    │ Page     │    │  counter)  │    │            │  │  member)  │
                    └──────────┘    └────────────┘    └────────────┘  └───────────┘
```

### Detail Steps

1. Customer scan QR code di meja (e.g., A01)
2. Browser buka `menu.creativepos.app/{tenant}/{outlet}/table/A01`
3. Tampil digital menu dengan kategori & produk
4. Customer browse, lihat foto, cek availability
5. Add to cart (bisa tambah notes per item)
6. Optional: Login sebagai member (earn points)
7. Checkout → konfirmasi order
8. Order masuk ke:
   - Kitchen Display (status: Pending)
   - POS (sebagai open order di meja A01)
9. Customer bisa:
   - Track status order
   - Call waiter
   - Request bill

---

## 5. Kitchen Display Flow

```
┌──────────────┐    ┌───────────────┐    ┌──────────────┐    ┌──────────────┐
│ New Order    │───▶│ Status:       │───▶│ Status:      │───▶│ Status:      │
│ Received     │    │ PENDING       │    │ COOKING      │    │ READY        │
│ (WebSocket)  │    │ (sound alert) │    │ (chef start) │    │ (food done)  │
└──────────────┘    └───────────────┘    └──────────────┘    └──────┬───────┘
                                                                      │
                                                               ┌──────▼───────┐
                                                               │ Status:      │
                                                               │ SERVED       │
                                                               │ (waiter pick)│
                                                               └──────────────┘
```

---

## 6. Reservation Flow

### Customer-initiated

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Online   │───▶│ Select    │───▶│ Fill Form  │───▶│ Submit     │───▶│ Confirmation│
│ Booking  │    │ Date/Time │    │ name,phone,│    │ Reservation│    │ Email/WA  │
│ Page     │    │           │    │ guests     │    │            │    │ Sent      │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └───────────┘
```

### Staff-managed

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Manager/ │───▶│ Create    │───▶│ Assign     │───▶│ Confirm    │───▶│ Reminder  │
│ Waiter   │    │ Reservation│    │ Table      │    │ to Customer│    │ H-1, H-0  │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └───────────┘
                                                                          │
┌──────────┐    ┌───────────┐    ┌────────────┐                         │
│ Complete │◀───│ Serve     │◀───│ Mark       │◀────────────────────────┘
│          │    │ Customer  │    │ Arrived    │    (customer datang)
└──────────┘    └───────────┘    └────────────┘
```

---

## 7. Delivery Flow

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Customer │───▶│ Add       │───▶│ Enter      │───▶│ Calculate  │───▶│ Confirm & │
│ Order    │    │ Products  │    │ Address    │    │ Shipping   │    │ Pay       │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └─────┬─────┘
                                                                            │
         ┌──────────┐    ┌───────────┐    ┌────────────┐    ┌─────────────▼──┐
         │ Completed│◀───│ Delivered │◀───│ Driver     │◀───│ Kitchen Prepare│
         │ + Rating │    │ (proof)   │    │ Pickup     │    │ → Ready        │
         └──────────┘    └───────────┘    └────────────┘    └────────────────┘
```

### Delivery Status Progression

```
WAITING → PROCESSING → COOKING → READY → DELIVERING → COMPLETED
```

---

## 8. Member & Loyalty Flow

### Registration

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Register │───▶│ Fill      │───▶│ Verify     │───▶│ Generate   │───▶│ Member    │
│ (portal/ │    │ Profile   │    │ Phone/Email│    │ QR+Barcode │    │ Active    │
│  POS)    │    │           │    │            │    │ + Code     │    │ (Bronze)  │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └───────────┘
```

### Point Earn & Redeem

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐
│ POS      │───▶│ Auto      │───▶│ Check Tier │───▶│ Apply Tier │
│ Scan     │    │ Calculate │    │ Upgrade?   │    │ Benefits   │
│ Member   │    │ Points    │    │            │    │            │
└──────────┘    └───────────┘    └────────────┘    └────────────┘

Redeem: Member Portal/POS → Select Reward → Confirm → Points Deducted → Reward Applied
```

---

## 9. Member Wallet Flow

```
Top Up:  Member/Cashier → Enter Amount → Select Method (Cash/Transfer/Gateway) → Confirm → Balance Updated

Payment: POS → Scan Member → Select "Wallet Payment" → Confirm → Balance Deducted

Withdraw: Member Portal → Request Withdraw → Manager Approve → Process → Balance Deducted

Transfer: Member Portal → Enter Target Member → Enter Amount → Confirm → Both Balances Updated
```

---

## 10. CRM Ticketing Flow

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Customer │───▶│ Create    │───▶│ Auto       │───▶│ Agent      │───▶│ Agent     │
│ Contact  │    │ Ticket    │    │ Assign     │    │ Assigned   │    │ Responds  │
│ (WA/TG/  │    │           │    │ (round     │    │ (SLA start)│    │           │
│  Email)  │    │           │    │  robin)    │    │            │    │           │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └─────┬─────┘
                                                                              │
                    ┌──────────┐    ┌────────────┐    ┌────────────┐  ┌─────▼─────┐
                    │ CSAT     │◀───│ Closed     │◀───│ Resolved   │◀─│ Troubleshoot│
                    │ Survey   │    │            │    │            │  │             │
                    └──────────┘    └────────────┘    └────────────┘  └─────────────┘
```

---

## 11. Inventory Management Flow

### Purchase Order → Goods Receipt

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Create   │───▶│ Submit    │───▶│ Manager    │───▶│ Send to    │───▶│ Receive   │
│ PO       │    │ for       │    │ Approve    │    │ Supplier   │    │ Goods     │
│          │    │ Approval  │    │            │    │            │    │ (GRN)     │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └─────┬─────┘
                                                                              │
                                                                       ┌──────▼──────┐
                                                                       │ Stock       │
                                                                       │ Updated     │
                                                                       └─────────────┘
```

### Stock Opname

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Create   │───▶│ Physical  │───▶│ Input      │───▶│ Review     │───▶│ Approve & │
│ Opname   │    │ Count     │    │ Actual Qty │    │ Variance   │    │ Adjust    │
│ Session  │    │           │    │ per Product│    │ Report     │    │ Stock     │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └───────────┘
```

---

## 12. Reporting Flow

```
┌──────────┐    ┌───────────┐    ┌────────────┐    ┌────────────┐    ┌───────────┐
│ Select   │───▶│ Set       │───▶│ Set        │───▶│ Generate   │───▶│ Export    │
│ Report   │    │ Date Range│    │ Filters    │    │ Report     │    │ PDF/Excel │
│ Type     │    │           │    │ (outlet)   │    │            │    │ /CSV      │
└──────────┘    └───────────┘    └────────────┘    └────────────┘    └───────────┘
```

---

## 13. Role-Based Landing Page

| Role | Default Landing |
|------|----------------|
| Super Admin | Platform Dashboard |
| Owner | Business Dashboard |
| Manager | Business Dashboard |
| Supervisor | POS + Dashboard |
| Cashier | POS Screen |
| Waiter | Table Orders |
| Kitchen | Kitchen Display |
| Driver | Delivery List |
| Customer Service | Ticket Queue |
| Customer | Member Portal |