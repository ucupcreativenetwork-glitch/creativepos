# TAHAP 1 — Use Case Diagram

## CreativePOS Use Case Model

---

## 1. Platform Level (Super Admin)

```mermaid
graph LR
    SA((Super Admin))
    
    subgraph Platform Management
        UC01[Manage Tenants]
        UC02[Manage Packages]
        UC03[Manage Subscriptions]
        UC04[Manage Billing]
        UC05[View Platform Dashboard]
        UC06[System Monitoring]
        UC07[Impersonate Tenant]
    end
    
    SA --> UC01
    SA --> UC02
    SA --> UC03
    SA --> UC04
    SA --> UC05
    SA --> UC06
    SA --> UC07
```

### Use Case Detail — Platform

| UC ID | Use Case | Actor | Description |
|-------|----------|-------|-------------|
| UC-P01 | Manage Tenants | Super Admin | CRUD tenant, suspend, activate, delete |
| UC-P02 | Manage Packages | Super Admin | CRUD subscription packages & features |
| UC-P03 | Manage Subscriptions | Super Admin | Create, renew, upgrade/downgrade |
| UC-P04 | Manage Billing | Super Admin | Invoice generation, payment tracking |
| UC-P05 | View Platform Dashboard | Super Admin | MRR, churn, tenant metrics |
| UC-P06 | System Monitoring | Super Admin | Health check, queue status |
| UC-P07 | Impersonate Tenant | Super Admin | Login as tenant for support |

---

## 2. Authentication Module

```mermaid
graph LR
    User((User))
    Guest((Guest))
    Google((Google OAuth))
    
    subgraph Authentication
        UC10[Login]
        UC11[Register Tenant]
        UC12[Forgot Password]
        UC13[Reset Password]
        UC14[Email Verification]
        UC15[OTP Verification]
        UC16[WhatsApp OTP]
        UC17[Google Login]
        UC18[Enable 2FA]
        UC19[Manage Sessions]
        UC20[Manage Devices]
    end
    
    subgraph Authorization
        UC21[Manage Roles]
        UC22[Manage Permissions]
        UC23[Assign Roles]
    end
    
    User --> UC10
    User --> UC12
    User --> UC18
    User --> UC19
    User --> UC20
    Guest --> UC11
    Google --> UC17
    UC10 -.-> UC15
    UC10 -.-> UC16
    UC10 -.-> UC18
    UC11 -.-> UC14
```

---

## 3. POS Module

```mermaid
graph LR
    Cashier((Cashier))
    Supervisor((Supervisor))
    System((System))
    
    subgraph POS Operations
        UC30[Quick Sale]
        UC31[Scan Barcode/QR]
        UC32[Hold Transaction]
        UC33[Resume Transaction]
        UC34[Split Bill]
        UC35[Merge Bill]
        UC36[Apply Discount]
        UC37[Process Payment]
        UC38[Print Receipt]
        UC39[Void Transaction]
        UC40[Refund Transaction]
        UC41[Return Product]
        UC42[Open/Close Shift]
        UC43[Scan Member]
    end
    
    Cashier --> UC30
    Cashier --> UC31
    Cashier --> UC32
    Cashier --> UC33
    Cashier --> UC34
    Cashier --> UC35
    Cashier --> UC36
    Cashier --> UC37
    Cashier --> UC38
    Cashier --> UC42
    Cashier --> UC43
    Supervisor --> UC39
    Supervisor --> UC40
    Supervisor --> UC41
    UC30 --> UC37
    UC37 --> UC38
    UC37 -.-> UC43
    UC39 -.->|requires approval| Supervisor
    UC40 -.->|requires approval| Supervisor
```

---

## 4. Inventory Module

```mermaid
graph LR
    Manager((Manager))
    Supervisor((Supervisor))
    System((System))
    
    subgraph Product Management
        UC50[Manage Categories]
        UC51[Manage Products]
        UC52[Manage Variants]
        UC53[Manage Bundles]
    end
    
    subgraph Stock Management
        UC54[Stock In]
        UC55[Stock Out]
        UC56[Stock Transfer]
        UC57[Stock Adjustment]
        UC58[Stock Opname]
    end
    
    subgraph Procurement
        UC59[Manage Suppliers]
        UC60[Create Purchase Order]
        UC61[Approve Purchase Order]
        UC62[Goods Receipt]
        UC63[Purchase Return]
    end
    
    Manager --> UC50
    Manager --> UC51
    Manager --> UC59
    Manager --> UC60
    Manager --> UC61
    Manager --> UC58
    Supervisor --> UC54
    Supervisor --> UC55
    Supervisor --> UC56
    Supervisor --> UC57
    Supervisor --> UC62
    Supervisor --> UC63
    System -.->|auto deduct| UC55
```

---

## 5. Customer-Facing Modules

```mermaid
graph LR
    Customer((Customer))
    Waiter((Waiter))
    Kitchen((Kitchen Staff))
    Driver((Driver))
    
    subgraph QR Digital Menu
        UC70[Scan Table QR]
        UC71[Browse Menu]
        UC72[Add to Cart]
        UC73[Checkout Order]
        UC74[Call Waiter]
    end
    
    subgraph Kitchen Display
        UC80[View Order Queue]
        UC81[Update Order Status]
        UC82[Filter by Station]
    end
    
    subgraph Reservation
        UC90[Create Reservation]
        UC91[Manage Reservation]
        UC92[Send Reminder]
    end
    
    subgraph Delivery
        UC100[Create Delivery Order]
        UC101[Track Delivery]
        UC102[Assign Driver]
        UC103[Update Delivery Status]
        UC104[GPS Tracking]
    end
    
    Customer --> UC70
    Customer --> UC71
    Customer --> UC72
    Customer --> UC73
    Customer --> UC74
    Customer --> UC90
    Customer --> UC100
    Customer --> UC101
    Kitchen --> UC80
    Kitchen --> UC81
    Kitchen --> UC82
    Waiter --> UC91
    Waiter --> UC92
    Driver --> UC103
    Driver --> UC104
```

---

## 6. Loyalty, Wallet & CRM

```mermaid
graph LR
    Customer((Customer))
    Cashier((Cashier))
    Manager((Manager))
    CSAgent((CS Agent))
    
    subgraph Loyalty
        UC110[Register Member]
        UC111[Earn Points]
        UC112[Redeem Points]
        UC113[View Tier Status]
        UC114[Birthday Reward]
        UC115[Referral Program]
    end
    
    subgraph Wallet
        UC120[Top Up Wallet]
        UC121[Withdraw Wallet]
        UC122[Transfer Wallet]
        UC123[Pay with Wallet]
        UC124[View Wallet History]
    end
    
    subgraph CRM
        UC130[Create Ticket]
        UC131[Assign Ticket]
        UC132[Resolve Ticket]
        UC133[Rate Service]
        UC134[Browse Knowledge Base]
        UC135[Manage FAQ]
    end
    
    Customer --> UC110
    Customer --> UC112
    Customer --> UC113
    Customer --> UC115
    Customer --> UC120
    Customer --> UC121
    Customer --> UC122
    Customer --> UC124
    Customer --> UC130
    Customer --> UC133
    Customer --> UC134
    Cashier --> UC111
    Cashier --> UC123
    Manager --> UC135
    CSAgent --> UC131
    CSAgent --> UC132
```

---

## 7. Reporting & Dashboard

```mermaid
graph LR
    Owner((Owner))
    Manager((Manager))
    System((System))
    
    subgraph Dashboard
        UC140[View KPI Dashboard]
        UC141[View Sales Charts]
        UC142[View Alerts]
        UC143[Filter by Outlet]
    end
    
    subgraph Reporting
        UC150[Generate Sales Report]
        UC151[Generate Inventory Report]
        UC152[Generate P&L Report]
        UC153[Generate Cash Flow Report]
        UC154[Export Report]
        UC155[Schedule Report]
    end
    
    Owner --> UC140
    Owner --> UC150
    Owner --> UC152
    Owner --> UC153
    Owner --> UC154
    Owner --> UC155
    Manager --> UC140
    Manager --> UC141
    Manager --> UC142
    Manager --> UC143
    Manager --> UC150
    Manager --> UC151
    Manager --> UC154
    System -.->|scheduled| UC155
```

---

## 8. Complete System Use Case Overview

```mermaid
graph TB
    subgraph Actors
        SA((Super Admin))
        OW((Owner))
        MG((Manager))
        SV((Supervisor))
        CS((Cashier))
        WT((Waiter))
        KT((Kitchen))
        DR((Driver))
        CSA((CS Agent))
        CU((Customer))
    end
    
    subgraph CreativePOS System
        direction TB
        AUTH[Authentication]
        DASH[Dashboard]
        POS[Point of Sale]
        INV[Inventory]
        LOY[Loyalty]
        WAL[Wallet]
        QRM[QR Menu]
        KDS[Kitchen Display]
        RES[Reservation]
        DEL[Delivery]
        CRM[CRM]
        WA[WhatsApp]
        RPT[Reporting]
        SET[Settings]
        AUD[Audit/Security]
        PLT[Platform Mgmt]
    end
    
    SA --> PLT
    OW --> AUTH
    OW --> DASH
    OW --> POS
    OW --> INV
    OW --> LOY
    OW --> RPT
    OW --> SET
    OW --> AUD
    MG --> DASH
    MG --> POS
    MG --> INV
    MG --> LOY
    MG --> RES
    MG --> DEL
    MG --> CRM
    MG --> RPT
    MG --> SET
    SV --> POS
    SV --> INV
    CS --> POS
    CS --> LOY
    CS --> WAL
    WT --> POS
    WT --> RES
    KT --> KDS
    DR --> DEL
    CSA --> CRM
    CU --> QRM
    CU --> LOY
    CU --> WAL
    CU --> RES
    CU --> DEL
    CU --> CRM
    
    POS --> INV
    POS --> LOY
    POS --> WAL
    POS --> KDS
    POS --> WA
    QRM --> POS
    QRM --> KDS
    DEL --> KDS
    DEL --> WA
    RES --> WA
    LOY --> WA
    CRM --> WA
```

---

## Use Case Summary

| Module | Total Use Cases | Primary Actors |
|--------|----------------|----------------|
| Platform | 7 | Super Admin |
| Authentication | 14 | All Users |
| Dashboard | 6 | Owner, Manager |
| POS | 14 | Cashier, Supervisor |
| Inventory | 14 | Manager, Supervisor |
| Loyalty | 6 | Customer, Cashier |
| Wallet | 5 | Customer, Cashier |
| QR Menu | 5 | Customer |
| Kitchen Display | 3 | Kitchen |
| Reservation | 3 | Customer, Waiter, Manager |
| Delivery | 5 | Customer, Driver, Manager |
| CRM | 6 | Customer, CS Agent |
| WhatsApp | 4 | System, Manager |
| Reporting | 6 | Owner, Manager |
| Settings | 5 | Owner, Manager |
| Audit | 4 | Owner |
| **Total** | **~107** | **10 actor types** |