# TAHAP 1 — Activity Diagram

## CreativePOS Activity Diagrams

---

## AD-01: POS Sale Transaction

```mermaid
flowchart TD
    A([Start]) --> B{Shift Open?}
    B -->|No| C[Open Shift]
    C --> D[Enter Opening Cash]
    D --> E[Scan/Search Product]
    B -->|Yes| E
    
    E --> F[Add to Cart]
    F --> G{More Products?}
    G -->|Yes| E
    G -->|No| H{Apply Discount?}
    
    H -->|Yes| I[Select Discount Type]
    I --> J{Type?}
    J -->|Percentage| K[Enter %]
    J -->|Nominal| L[Enter Amount]
    J -->|Voucher| M[Enter Voucher Code]
    J -->|Promo| N[Auto-Apply Promo]
    K --> O[Calculate Total]
    L --> O
    M --> O
    N --> O
    H -->|No| O
    
    O --> P{Scan Member?}
    P -->|Yes| Q[Scan Member QR]
    Q --> R[Apply Member Benefits]
    R --> S[Select Payment Method]
    P -->|No| S
    
    S --> T{Payment Type?}
    T -->|Cash| U[Enter Cash Amount]
    U --> V[Calculate Change]
    T -->|Transfer| W[Confirm Transfer]
    T -->|QRIS| X[Generate QRIS]
    X --> Y{Payment Confirmed?}
    Y -->|No| X
    Y -->|Yes| Z[Process Payment]
    T -->|Card| Z
    T -->|E-Wallet| Z
    T -->|Wallet| AA[Verify Balance]
    AA --> AB{Sufficient?}
    AB -->|No| AC[Insufficient Alert]
    AC --> S
    AB -->|Yes| Z
    V --> Z
    W --> Z
    
    Z --> AD[Deduct Stock]
    AD --> AE{Member?}
    AE -->|Yes| AF[Earn Points]
    AE -->|No| AG[Print Receipt]
    AF --> AG
    
    AG --> AH{Dine-in?}
    AH -->|Yes| AI[Send to Kitchen]
    AI --> AJ([End])
    AH -->|No| AJ
```

---

## AD-02: QR Digital Menu Order

```mermaid
flowchart TD
    A([Customer Scans QR]) --> B[Load Digital Menu]
    B --> C[Display Categories & Products]
    C --> D[Customer Browses Menu]
    D --> E[Select Product]
    E --> F{Available?}
    F -->|No| G[Show Out of Stock]
    G --> D
    F -->|Yes| H[Add to Cart]
    H --> I{Add Notes?}
    I -->|Yes| J[Enter Item Notes]
    J --> K{More Items?}
    I -->|No| K
    K -->|Yes| D
    K -->|No| L[View Cart Summary]
    
    L --> M{Login as Member?}
    M -->|Yes| N[Member Login/Register]
    N --> O[Apply Member Benefits]
    O --> P[Confirm Order]
    M -->|No| P
    
    P --> Q[Create Order]
    Q --> R[Link to Table Number]
    R --> S[Send to Kitchen Display]
    S --> T[Create POS Open Order]
    T --> U[Show Order Confirmation]
    U --> V[Show Order Tracking Page]
    
    V --> W{Customer Action?}
    W -->|Track Status| X[WebSocket Update]
    X --> V
    W -->|Call Waiter| Y[Notify Waiter]
    Y --> V
    W -->|Request Bill| Z[Notify Cashier]
    Z --> AA([Wait for Payment at POS])
```

---

## AD-03: Kitchen Display Order Processing

```mermaid
flowchart TD
    A([New Order Received]) --> B[Play Sound Alert]
    B --> C[Display on KDS Screen]
    C --> D[Status: PENDING]
    D --> E[Chef Views Order]
    E --> F[Chef Starts Cooking]
    F --> G[Status: COOKING]
    G --> H[Start Order Timer]
    H --> I{Cooking Complete?}
    I -->|No| J{Timeout Alert?}
    J -->|Yes| K[Highlight Red]
    K --> I
    J -->|No| I
    I -->|Yes| L[Chef Bumps Order]
    L --> M[Status: READY]
    M --> N[Notify Waiter]
    N --> O[Waiter Picks Up]
    O --> P[Waiter Serves to Table]
    P --> Q[Status: SERVED]
    Q --> R([Order Complete])
```

---

## AD-04: Purchase Order to Goods Receipt

```mermaid
flowchart TD
    A([Low Stock Alert]) --> B[Manager Reviews Stock]
    B --> C[Create Purchase Order]
    C --> D[Add Products & Quantities]
    D --> E[Select Supplier]
    E --> F[Submit for Approval]
    F --> G{PO Value?}
    G -->|> Rp 5M| H[Owner Approval Required]
    G -->|<= Rp 5M| I[Manager Self-Approve]
    H --> J{Approved?}
    J -->|No| K[Reject with Reason]
    K --> L([End - Rejected])
    J -->|Yes| M[PO Approved]
    I --> M
    
    M --> N[Send PO to Supplier]
    N --> O[Status: ORDERED]
    O --> P[Wait for Delivery]
    P --> Q[Goods Arrive]
    Q --> R[Create Goods Receipt]
    R --> S[Match PO Items]
    S --> T{All Items Received?}
    T -->|Yes| U[Full Receipt]
    T -->|No| V[Partial Receipt]
    V --> W[Update Remaining PO]
    U --> X[Update Stock Levels]
    W --> X
    X --> Y[Generate GRN Report]
    Y --> Z([End - Complete])
```

---

## AD-05: Member Registration & Point Earn

```mermaid
flowchart TD
    A([Start]) --> B{Registration Channel?}
    B -->|POS| C[Cashier Opens Register Form]
    B -->|Portal| D[Customer Self-Register]
    B -->|QR Menu| D
    
    C --> E[Fill Member Data]
    D --> E
    E --> F[Name, Phone, Email, Birthday]
    F --> G[Verify Phone/Email]
    G --> H{Verification OK?}
    H -->|No| I[Show Error]
    I --> E
    H -->|Yes| J[Generate Member Code]
    J --> K[Generate QR & Barcode]
    K --> L[Assign Bronze Tier]
    L --> M[Send Welcome Notification]
    M --> N([Member Active])
    
    subgraph Point Earn at POS
        O([POS Transaction]) --> P[Scan Member]
        P --> Q[Calculate Points]
        Q --> R["Points = Amount / Config Rate"]
        R --> S[Apply Tier Multiplier]
        S --> T[Add Points to Balance]
        T --> U[Log Point Transaction]
        U --> V{Tier Upgrade?}
        V -->|Yes| W[Upgrade Tier]
        W --> X[Send Upgrade Notification]
        X --> Y([End])
        V -->|No| Y
    end
```

---

## AD-06: Delivery Order Lifecycle

```mermaid
flowchart TD
    A([Customer Places Order]) --> B[Enter Delivery Address]
    B --> C[Validate Delivery Zone]
    C --> D{In Zone?}
    D -->|No| E[Reject - Out of Zone]
    E --> F([End])
    D -->|Yes| G[Calculate Shipping Fee]
    G --> H{Fee Type?}
    H -->|Flat| I[Apply Flat Rate]
    H -->|Distance| J[Calculate via Maps API]
    I --> K[Show Order Summary]
    J --> K
    K --> L[Customer Confirms & Pays]
    L --> M[Status: WAITING]
    M --> N[Status: PROCESSING]
    N --> O[Send to Kitchen]
    O --> P[Status: COOKING]
    P --> Q[Status: READY]
    Q --> R{Assign Driver}
    R --> S{Driver Type?}
    S -->|Internal| T[Assign Internal Driver]
    S -->|External| U[Assign External Driver]
    T --> V[Driver Accepts]
    U --> V
    V --> W[Driver Navigates to Outlet]
    W --> X[Driver Picks Up Order]
    X --> Y[Status: DELIVERING]
    Y --> Z[GPS Tracking Active]
    Z --> AA[Driver Arrives at Customer]
    AA --> AB[Take Delivery Proof Photo]
    AB --> AC[Status: COMPLETED]
    AC --> AD[Send Completion Notification]
    AD --> AE[Customer Rates Delivery]
    AE --> AF([End])
```

---

## AD-07: Reservation Flow

```mermaid
flowchart TD
    A([Reservation Request]) --> B[Select Date & Time]
    B --> C[Enter Guest Count]
    C --> D[Check Table Availability]
    D --> E{Available?}
    E -->|No| F[Show Alternative Slots]
    F --> G{Customer Accepts?}
    G -->|No| H[Cancel Request]
    H --> I([End])
    G -->|Yes| B
    E -->|Yes| J[Create Reservation]
    J --> K[Status: PENDING]
    K --> L[Staff Reviews]
    L --> M[Confirm Reservation]
    M --> N[Status: CONFIRMED]
    N --> O[Assign Table]
    O --> P[Send Confirmation WA/Email]
    
    P --> Q[Schedule H-1 Reminder]
    Q --> R[Schedule H-0 Reminder]
    R --> S[Wait for Reservation Date]
    
    S --> T{Customer Arrives?}
    T -->|Yes| U[Mark as ARRIVED]
    U --> V[Seat at Assigned Table]
    V --> W[Create POS Order]
    W --> X[Status: COMPLETED]
    X --> Y([End])
    
    T -->|No - 15min late| Z[Mark as NO-SHOW]
    Z --> AA[Status: CANCELLED]
    AA --> AB[Release Table]
    AB --> I
```

---

## AD-08: Subscription Billing Cycle

```mermaid
flowchart TD
    A([Billing Date Approaching]) --> B[Generate Invoice]
    B --> C[Send Invoice Email]
    C --> D[Status: INVOICED]
    D --> E{Payment Received?}
    E -->|Yes| F[Record Payment]
    F --> G[Extend Subscription]
    G --> H[Send Receipt]
    H --> I([Active - Renewed])
    
    E -->|No - Due Date Passed| J[Enter Grace Period]
    J --> K[Send Reminder]
    K --> L{Payment in Grace?}
    L -->|Yes| F
    L -->|No - Grace Ended| M[Suspend Tenant]
    M --> N[Send Suspension Notice]
    N --> O[Disable Write Operations]
    O --> P{Payment After Suspend?}
    P -->|Yes| Q[Reactivate Tenant]
    Q --> I
    P -->|No - 90 days| R[Archive Tenant Data]
    R --> S[Status: TERMINATED]
    S --> T([End])
```

---

## AD-09: CRM Ticket Resolution

```mermaid
flowchart TD
    A([Ticket Created]) --> B[Auto-Generate Ticket Number]
    B --> C[Set Priority]
    C --> D[Auto-Assign Agent]
    D --> E[Start SLA Timer]
    E --> F[Status: OPEN]
    F --> G[Agent Reviews Ticket]
    G --> H{Need More Info?}
    H -->|Yes| I[Status: PENDING]
    I --> J[Request Info from Customer]
    J --> K[Customer Replies]
    K --> G
    H -->|No| L[Agent Troubleshoots]
    L --> M{Resolved?}
    M -->|No| N{SLA Breach?}
    N -->|Yes| O[Escalate to Senior]
    O --> L
    N -->|No| L
    M -->|Yes| P[Status: RESOLVED]
    P --> Q[Notify Customer]
    Q --> R{Customer Satisfied?}
    R -->|Yes| S[Status: CLOSED]
    S --> T[Send CSAT Survey]
    T --> U[Customer Rates 1-5]
    U --> V([End])
    R -->|No| W[Reopen Ticket]
    W --> G
```

---

## AD-10: Stock Opname Process

```mermaid
flowchart TD
    A([Start Opname]) --> B[Manager Creates Opname Session]
    B --> C[Select Warehouse/Outlet]
    C --> D[Generate Product Checklist]
    D --> E[Staff Physical Count]
    E --> F[Input Actual Quantities]
    F --> G{All Products Counted?}
    G -->|No| E
    G -->|Yes| H[Calculate Variance]
    H --> I[Generate Variance Report]
    I --> J{Variance Acceptable?}
    J -->|Review Needed| K[Manager Investigates]
    K --> L{Approve Adjustment?}
    L -->|No| M[Recount Required]
    M --> E
    L -->|Yes| N[Apply Stock Adjustment]
    J -->|Acceptable| N
    N --> O[Update Stock Levels]
    O --> P[Close Opname Session]
    P --> Q[Generate Opname Report]
    Q --> R([End])
```