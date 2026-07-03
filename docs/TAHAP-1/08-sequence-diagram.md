# TAHAP 1 — Sequence Diagram

## CreativePOS Sequence Diagrams

---

## SD-01: User Login with 2FA

```mermaid
sequenceDiagram
    actor User
    participant FE as Next.js Frontend
    participant API as Laravel API
    participant Auth as Auth Service
    participant DB as MySQL
    participant Redis as Redis Cache
    participant WA as WhatsApp API

    User->>FE: Enter email & password
    FE->>API: POST /api/auth/login
    API->>Auth: validateCredentials()
    Auth->>DB: SELECT user WHERE email
    DB-->>Auth: User record
    Auth->>Auth: Verify password hash
    
    alt Invalid credentials
        Auth-->>API: 401 Unauthorized
        API-->>FE: Error response
        FE-->>User: Show error message
    else Valid credentials
        Auth->>DB: Check 2FA enabled?
        
        alt 2FA Enabled
            Auth-->>API: requires_2fa: true
            API-->>FE: 2FA challenge
            FE-->>User: Show TOTP input
            
            alt TOTP Method
                User->>FE: Enter TOTP code
                FE->>API: POST /api/auth/2fa/verify
                API->>Auth: verifyTOTP()
                Auth-->>API: verified
            else WhatsApp OTP Method
                Auth->>WA: Send OTP
                WA-->>User: WhatsApp message
                User->>FE: Enter OTP
                FE->>API: POST /api/auth/otp/verify
                API->>Auth: verifyOTP()
                Auth->>Redis: Check OTP cache
                Auth-->>API: verified
            end
        end
        
        Auth->>Auth: Generate Sanctum token
        Auth->>DB: INSERT login_history
        Auth->>DB: UPDATE last_login_at
        Auth->>Redis: Cache session
        API-->>FE: { token, user, permissions }
        FE->>FE: Store token in Zustand
        FE-->>User: Redirect to dashboard
    end
```

---

## SD-02: POS Sale Transaction

```mermaid
sequenceDiagram
    actor Cashier
    participant POS as POS Frontend
    participant API as Laravel API
    participant POS_Svc as POS Service
    participant Inv_Svc as Inventory Service
    participant Loy_Svc as Loyalty Service
    participant DB as MySQL
    participant Queue as Redis Queue
    participant WS as WebSocket
    participant Printer as Thermal Printer

    Cashier->>POS: Scan product barcode
    POS->>API: GET /api/products/barcode/{code}
    API->>DB: SELECT product (tenant scoped)
    DB-->>API: Product data
    API-->>POS: Product details
    POS->>POS: Add to cart

    Cashier->>POS: Scan member QR
    POS->>API: GET /api/members/qr/{code}
    API->>DB: SELECT member
    DB-->>API: Member data
    API-->>POS: Member profile + tier

    Cashier->>POS: Select payment & confirm
    POS->>API: POST /api/pos/transactions
    
    API->>POS_Svc: createTransaction()
    POS_Svc->>DB: BEGIN TRANSACTION
    POS_Svc->>DB: INSERT sale_transaction
    POS_Svc->>DB: INSERT sale_transaction_items
    POS_Svc->>DB: INSERT payment_records
    
    POS_Svc->>Inv_Svc: deductStock(items)
    Inv_Svc->>DB: UPDATE product_stocks
    Inv_Svc->>DB: INSERT stock_movements
    
    alt Member attached
        POS_Svc->>Loy_Svc: earnPoints(member, amount)
        Loy_Svc->>DB: INSERT point_transactions
        Loy_Svc->>DB: UPDATE member_points
        Loy_Svc->>Loy_Svc: checkTierUpgrade()
    end
    
    POS_Svc->>DB: COMMIT
    POS_Svc-->>API: Transaction result
    
    API->>Queue: Dispatch SendReceiptJob
    API->>WS: Broadcast NewOrder (if dine-in)
    API-->>POS: Transaction complete
    
    POS->>Printer: Print receipt (ESC/POS)
    POS-->>Cashier: Show success + change
    
    Queue->>Queue: SendReceiptJob
    Note over Queue: WhatsApp/Email receipt async
```

---

## SD-03: QR Digital Menu Order

```mermaid
sequenceDiagram
    actor Customer
    participant Menu as QR Menu (PWA)
    participant API as Laravel API
    participant Order_Svc as Order Service
    participant DB as MySQL
    participant WS as WebSocket Server
    participant KDS as Kitchen Display
    participant POS as POS Terminal

    Customer->>Menu: Scan QR code (Table A01)
    Menu->>API: GET /api/public/menu/{tenant}/{outlet}
    API->>DB: SELECT categories, products, availability
    DB-->>API: Menu data
    API-->>Menu: Digital menu JSON
    Menu-->>Customer: Display menu

    Customer->>Menu: Add items to cart
    Customer->>Menu: Checkout
    Menu->>API: POST /api/public/orders
    
    API->>Order_Svc: createGuestOrder()
    Order_Svc->>DB: INSERT orders
    Order_Svc->>DB: INSERT order_items
    Order_Svc->>DB: Link table_id = A01
    Order_Svc-->>API: Order created

    API->>WS: Broadcast OrderCreated
    WS->>KDS: New order (status: PENDING)
    WS->>POS: New table order notification
    
    API-->>Menu: Order confirmation + tracking URL
    Menu-->>Customer: Show order status page

    loop Order Status Updates
        KDS->>API: PATCH /api/kitchen/orders/{id}/status
        API->>DB: UPDATE order status
        API->>WS: Broadcast StatusUpdated
        WS->>Menu: Real-time status update
        Menu-->>Customer: Update UI (Cooking → Ready)
    end
```

---

## SD-04: Tenant Registration & Onboarding

```mermaid
sequenceDiagram
    actor Owner
    participant FE as Next.js Frontend
    participant API as Laravel API
    participant Tenant_Svc as Tenant Service
    participant Auth_Svc as Auth Service
    participant DB as MySQL
    participant Queue as Redis Queue
    participant Email as Email Service

    Owner->>FE: Fill registration form
    FE->>API: POST /api/auth/register
    
    API->>Tenant_Svc: createTenant()
    Tenant_Svc->>DB: BEGIN TRANSACTION
    Tenant_Svc->>DB: INSERT tenants
    Tenant_Svc->>DB: INSERT subscriptions (trial)
    Tenant_Svc->>DB: INSERT tenant_settings (defaults)
    
    Tenant_Svc->>Auth_Svc: createOwnerUser()
    Auth_Svc->>DB: INSERT users
    Auth_Svc->>DB: Assign role 'owner'
    Auth_Svc->>DB: INSERT model_has_roles
    
    Tenant_Svc->>DB: INSERT outlets (default)
    Tenant_Svc->>DB: COMMIT
    Tenant_Svc-->>API: Tenant + User created

    API->>Queue: Dispatch SendVerificationEmail
    API-->>FE: Registration success
    
    Queue->>Email: Send verification email
    Email-->>Owner: Verification link

    Owner->>FE: Click verification link
    FE->>API: GET /api/auth/verify-email/{token}
    API->>DB: UPDATE email_verified_at
    API-->>FE: Email verified

    Owner->>FE: Start Setup Wizard
    FE->>API: POST /api/setup/profile
    API->>DB: UPDATE tenant profile
    FE->>API: POST /api/setup/outlet
    FE->>API: POST /api/setup/categories
    FE->>API: POST /api/setup/products
    API-->>FE: Setup complete
    FE-->>Owner: Redirect to Dashboard
```

---

## SD-05: Purchase Order Approval & Goods Receipt

```mermaid
sequenceDiagram
    actor Manager
    actor Supervisor
    participant FE as Frontend
    participant API as Laravel API
    participant PO_Svc as Purchase Service
    participant Inv_Svc as Inventory Service
    participant DB as MySQL
    participant Queue as Redis Queue
    participant Notif as Notification Service

    Manager->>FE: Create Purchase Order
    FE->>API: POST /api/inventory/purchase-orders
    API->>PO_Svc: createPO()
    PO_Svc->>DB: INSERT purchase_orders
    PO_Svc->>DB: INSERT purchase_order_items
    PO_Svc-->>API: PO created (status: draft)
    
    Manager->>FE: Submit for approval
    FE->>API: POST /api/inventory/purchase-orders/{id}/submit
    API->>PO_Svc: submitForApproval()
    PO_Svc->>DB: UPDATE status = pending_approval
    PO_Svc->>Queue: Dispatch ApprovalNotification
    Queue->>Notif: Notify approver

    alt PO > Rp 5M
        actor Owner
        Owner->>FE: Review & Approve PO
        FE->>API: POST /api/inventory/purchase-orders/{id}/approve
    else PO <= Rp 5M
        Manager->>FE: Self-approve PO
        FE->>API: POST /api/inventory/purchase-orders/{id}/approve
    end
    
    API->>PO_Svc: approvePO()
    PO_Svc->>DB: UPDATE status = approved

    Note over Supervisor: Goods arrive from supplier

    Supervisor->>FE: Create Goods Receipt
    FE->>API: POST /api/inventory/goods-receipts
    API->>PO_Svc: createGRN()
    PO_Svc->>DB: INSERT goods_receipts
    PO_Svc->>DB: INSERT goods_receipt_items
    PO_Svc->>Inv_Svc: updateStock(items)
    Inv_Svc->>DB: UPDATE product_stocks
    Inv_Svc->>DB: INSERT stock_movements
    PO_Svc->>DB: UPDATE purchase_order status
    PO_Svc-->>API: GRN complete
    API-->>FE: Success
```

---

## SD-06: Delivery Order with Driver Assignment

```mermaid
sequenceDiagram
    actor Customer
    actor Driver
    participant FE as Frontend/PWA
    participant API as Laravel API
    participant Del_Svc as Delivery Service
    participant Maps as Maps API
    participant DB as MySQL
    participant WS as WebSocket
    participant WA as WhatsApp API

    Customer->>FE: Place delivery order
    FE->>API: POST /api/delivery/orders
    API->>Del_Svc: createDeliveryOrder()
    Del_Svc->>Maps: Calculate distance & ETA
    Maps-->>Del_Svc: Distance: 5.2km, ETA: 25min
    Del_Svc->>Del_Svc: Calculate shipping fee
    Del_Svc->>DB: INSERT delivery_orders
    Del_Svc-->>API: Order + shipping fee
    API-->>FE: Order summary
    Customer->>FE: Confirm & pay
    FE->>API: POST /api/delivery/orders/{id}/confirm

    API->>Del_Svc: assignDriver()
    Del_Svc->>DB: SELECT available drivers
    Del_Svc->>Maps: Calculate driver proximity
    Del_Svc->>DB: UPDATE assigned_driver_id
    Del_Svc->>WS: Notify driver
    Del_Svc->>WA: Send order notification

    WS->>Driver: New delivery assignment
    Driver->>FE: Accept delivery
    FE->>API: POST /api/delivery/orders/{id}/accept

    loop Delivery in Progress
        Driver->>FE: Update status
        FE->>API: PATCH /api/delivery/orders/{id}/status
        API->>DB: UPDATE status
        API->>WS: Broadcast status
        WS->>FE: Customer tracking update
        Driver->>FE: Send GPS location
        FE->>API: POST /api/delivery/orders/{id}/location
        API->>DB: INSERT delivery_tracking
    end

    Driver->>FE: Complete delivery + photo
    FE->>API: POST /api/delivery/orders/{id}/complete
    API->>DB: UPDATE status = completed
    API->>WA: Send completion notification
    API-->>FE: Request rating
    Customer->>FE: Rate 1-5 stars
    FE->>API: POST /api/delivery/orders/{id}/rate
    API->>DB: INSERT delivery_ratings
```

---

## SD-07: Multi-Tenant Data Isolation

```mermaid
sequenceDiagram
    actor User
    participant FE as Frontend
    participant API as Laravel API
    participant MW as Tenant Middleware
    participant Scope as Global Scope
    participant Policy as Authorization Policy
    participant DB as MySQL

    User->>FE: API Request (with token)
    FE->>API: GET /api/products (Bearer token)
    
    API->>MW: ResolveTenant
    MW->>MW: Extract tenant from token/user
    MW->>MW: Set tenant context (app()->instance)
    
    alt No tenant context
        MW-->>API: 403 Forbidden
        API-->>FE: Access denied
    end

    API->>Policy: authorize('viewAny', Product)
    Policy->>Policy: Check user role & permission
    Policy-->>API: Authorized

    API->>Scope: Product::query()
    Note over Scope: Global Scope auto-applies<br/>WHERE tenant_id = {current}
    Scope->>DB: SELECT * FROM products<br/>WHERE tenant_id = 1
    DB-->>Scope: Tenant-scoped results only
    Scope-->>API: Collection
    API-->>FE: JSON response
    
    Note over User,DB: Tenant B user CANNOT access Tenant A data
```

---

## SD-08: Subscription Billing

```mermaid
sequenceDiagram
    actor System as Scheduler (Cron)
    participant Billing as Billing Service
    participant DB as MySQL
    participant Queue as Redis Queue
    participant Email as Email Service
    actor Owner

    System->>Billing: checkDueSubscriptions()
    Billing->>DB: SELECT subscriptions WHERE due_date <= today
    DB-->>Billing: Due subscriptions list

    loop Each due subscription
        Billing->>DB: INSERT billing_invoices
        Billing->>Queue: Dispatch SendInvoiceEmail
        Queue->>Email: Send invoice to owner
        Email-->>Owner: Invoice email
    end

    Note over Billing: 7 days later (grace period)

    System->>Billing: checkOverdueSubscriptions()
    Billing->>DB: SELECT WHERE payment_status = overdue
    
    alt Payment received
        Owner->>Billing: Pay invoice
        Billing->>DB: UPDATE payment_status = paid
        Billing->>DB: EXTEND subscription period
        Billing->>Queue: Dispatch PaymentConfirmation
    else Grace period expired
        Billing->>DB: UPDATE tenant status = suspended
        Billing->>DB: UPDATE subscription status = suspended
        Billing->>Queue: Dispatch SuspensionNotice
        Queue->>Email: Send suspension email
        Email-->>Owner: Account suspended notice
    end
```

---

## SD-09: Real-time Kitchen Display (WebSocket)

```mermaid
sequenceDiagram
    participant POS as POS / QR Menu
    participant API as Laravel API
    participant Event as OrderCreated Event
    participant Queue as Queue Worker
    participant Reverb as Laravel Reverb (WS)
    participant KDS as Kitchen Display
    participant Waiter as Waiter App

    POS->>API: POST /api/orders (new order)
    API->>API: Create order in DB
    API->>Event: dispatch(OrderCreated)
    
    Event->>Queue: Handle async listeners
    Event->>Reverb: Broadcast to channel
    
    Note over Reverb: Channel: tenant.{id}.outlet.{id}.kitchen

    par Kitchen Display
        Reverb->>KDS: OrderCreated event
        KDS->>KDS: Add to queue (PENDING)
        KDS->>KDS: Play sound alert
    and Waiter Notification
        Reverb->>Waiter: NewOrder event
        Waiter->>Waiter: Show notification badge
    end

    KDS->>API: PATCH status → COOKING
    API->>Reverb: Broadcast OrderStatusUpdated
    Reverb->>KDS: Update order card
    Reverb->>POS: Update order tracking

    KDS->>API: PATCH status → READY
    API->>Reverb: Broadcast OrderStatusUpdated
    Reverb->>Waiter: OrderReady event
    Waiter->>Waiter: Alert: Food ready for Table A01

    Waiter->>API: PATCH status → SERVED
    API->>Reverb: Broadcast OrderStatusUpdated
    Reverb->>KDS: Remove from active queue
```

---

## SD-10: WhatsApp OTP Authentication

```mermaid
sequenceDiagram
    actor User
    participant FE as Frontend
    participant API as Laravel API
    participant OTP_Svc as OTP Service
    participant Redis as Redis
    participant WA as WhatsApp Business API
    participant DB as MySQL

    User->>FE: Request WhatsApp OTP
    FE->>API: POST /api/auth/otp/whatsapp
    API->>OTP_Svc: generateOTP(phone)
    
    OTP_Svc->>OTP_Svc: Generate 6-digit code
    OTP_Svc->>Redis: SET otp:{phone} = code (TTL: 5min)
    OTP_Svc->>DB: INSERT otp_logs
    OTP_Svc->>WA: POST /messages (template: otp_verification)
    WA-->>User: WhatsApp: "Kode OTP Anda: 123456"
    OTP_Svc-->>API: OTP sent
    API-->>FE: { message: "OTP sent", expires_in: 300 }

    User->>FE: Enter OTP code
    FE->>API: POST /api/auth/otp/verify
    API->>OTP_Svc: verifyOTP(phone, code)
    OTP_Svc->>Redis: GET otp:{phone}
    
    alt Invalid or expired
        OTP_Svc-->>API: Verification failed
        API-->>FE: 422 Invalid OTP
        FE-->>User: Show error
    else Valid
        OTP_Svc->>Redis: DEL otp:{phone}
        OTP_Svc->>DB: UPDATE otp_logs verified_at
        API->>API: Generate auth token
        API-->>FE: { token, user }
        FE-->>User: Login success
    end
```