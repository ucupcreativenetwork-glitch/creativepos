# TAHAP 3 — Backend Structure (Laravel 12)

## Project Root

```
D:\pos\
├── backend/                          # Laravel 12 Application
│   ├── app/
│   ├── bootstrap/
│   ├── config/
│   ├── database/
│   ├── routes/
│   ├── resources/
│   ├── storage/
│   ├── tests/
│   ├── composer.json
│   └── artisan
├── frontend/                         # Next.js 15 Application
├── docker/                           # Docker configuration
└── docs/                             # Documentation
```

---

## Backend Directory Structure

```
backend/
├── app/
│   ├── Modules/                      # Feature modules (Modular Architecture)
│   │   ├── Platform/
│   │   │   ├── Controllers/
│   │   │   │   ├── TenantController.php
│   │   │   │   ├── PackageController.php
│   │   │   │   ├── SubscriptionController.php
│   │   │   │   └── BillingController.php
│   │   │   ├── Services/
│   │   │   │   ├── TenantService.php
│   │   │   │   ├── SubscriptionService.php
│   │   │   │   └── BillingService.php
│   │   │   ├── Repositories/
│   │   │   │   ├── TenantRepository.php
│   │   │   │   └── SubscriptionRepository.php
│   │   │   ├── Models/
│   │   │   │   ├── Tenant.php
│   │   │   │   ├── Package.php
│   │   │   │   ├── Subscription.php
│   │   │   │   └── BillingInvoice.php
│   │   │   ├── Events/
│   │   │   ├── Listeners/
│   │   │   ├── Jobs/
│   │   │   ├── Policies/
│   │   │   ├── Requests/
│   │   │   ├── Resources/
│   │   │   └── Routes/
│   │   │       └── api.php
│   │   │
│   │   ├── Auth/
│   │   │   ├── Controllers/
│   │   │   │   ├── LoginController.php
│   │   │   │   ├── RegisterController.php
│   │   │   │   ├── PasswordController.php
│   │   │   │   ├── OtpController.php
│   │   │   │   ├── TwoFactorController.php
│   │   │   │   ├── SessionController.php
│   │   │   │   └── GoogleAuthController.php
│   │   │   ├── Services/
│   │   │   │   ├── AuthService.php
│   │   │   │   ├── OtpService.php
│   │   │   │   ├── TwoFactorService.php
│   │   │   │   └── SessionService.php
│   │   │   ├── Repositories/
│   │   │   ├── Models/
│   │   │   ├── Events/
│   │   │   │   ├── UserLoggedIn.php
│   │   │   │   └── UserRegistered.php
│   │   │   ├── Listeners/
│   │   │   ├── Jobs/
│   │   │   │   └── SendOtpJob.php
│   │   │   ├── Policies/
│   │   │   ├── Requests/
│   │   │   │   ├── LoginRequest.php
│   │   │   │   └── RegisterRequest.php
│   │   │   ├── Resources/
│   │   │   └── Routes/
│   │   │
│   │   ├── Tenant/
│   │   │   ├── Controllers/
│   │   │   │   ├── OutletController.php
│   │   │   │   ├── SettingsController.php
│   │   │   │   └── IntegrationController.php
│   │   │   ├── Services/
│   │   │   ├── Repositories/
│   │   │   ├── Models/
│   │   │   ├── Policies/
│   │   │   ├── Requests/
│   │   │   ├── Resources/
│   │   │   └── Routes/
│   │   │
│   │   ├── Inventory/
│   │   │   ├── Controllers/
│   │   │   │   ├── CategoryController.php
│   │   │   │   ├── ProductController.php
│   │   │   │   ├── StockController.php
│   │   │   │   ├── StockTransferController.php
│   │   │   │   ├── StockOpnameController.php
│   │   │   │   ├── SupplierController.php
│   │   │   │   ├── PurchaseOrderController.php
│   │   │   │   └── GoodsReceiptController.php
│   │   │   ├── Services/
│   │   │   │   ├── ProductService.php
│   │   │   │   ├── StockService.php
│   │   │   │   ├── PurchaseOrderService.php
│   │   │   │   └── StockOpnameService.php
│   │   │   ├── Repositories/
│   │   │   │   ├── ProductRepository.php
│   │   │   │   ├── StockRepository.php
│   │   │   │   └── PurchaseOrderRepository.php
│   │   │   ├── Models/
│   │   │   ├── Events/
│   │   │   │   ├── StockDeducted.php
│   │   │   │   └── StockBelowMinimum.php
│   │   │   ├── Listeners/
│   │   │   ├── Jobs/
│   │   │   ├── Policies/
│   │   │   ├── Requests/
│   │   │   ├── Resources/
│   │   │   └── Routes/
│   │   │
│   │   ├── POS/
│   │   │   ├── Controllers/
│   │   │   │   ├── TransactionController.php
│   │   │   │   ├── ShiftController.php
│   │   │   │   ├── PaymentController.php
│   │   │   │   ├── RefundController.php
│   │   │   │   ├── HeldTransactionController.php
│   │   │   │   ├── TableController.php
│   │   │   │   ├── PromoController.php
│   │   │   │   └── VoucherController.php
│   │   │   ├── Services/
│   │   │   │   ├── TransactionService.php
│   │   │   │   ├── PaymentService.php
│   │   │   │   ├── DiscountService.php
│   │   │   │   ├── ShiftService.php
│   │   │   │   └── ReceiptService.php
│   │   │   ├── Repositories/
│   │   │   │   └── TransactionRepository.php
│   │   │   ├── Models/
│   │   │   ├── Events/
│   │   │   │   ├── SaleTransactionCompleted.php
│   │   │   │   ├── TransactionVoided.php
│   │   │   │   └── RefundProcessed.php
│   │   │   ├── Listeners/
│   │   │   │   ├── DeductStockListener.php
│   │   │   │   ├── EarnPointsListener.php
│   │   │   │   └── SendReceiptListener.php
│   │   │   ├── Jobs/
│   │   │   │   └── SendReceiptJob.php
│   │   │   ├── Policies/
│   │   │   ├── Requests/
│   │   │   ├── Resources/
│   │   │   └── Routes/
│   │   │
│   │   ├── Loyalty/
│   │   │   ├── Controllers/
│   │   │   │   ├── MemberController.php
│   │   │   │   ├── PointController.php
│   │   │   │   ├── TierController.php
│   │   │   │   ├── RewardController.php
│   │   │   │   └── ReferralController.php
│   │   │   ├── Services/
│   │   │   │   ├── MemberService.php
│   │   │   │   ├── PointService.php
│   │   │   │   └── TierService.php
│   │   │   ├── Repositories/
│   │   │   ├── Models/
│   │   │   ├── Events/
│   │   │   ├── Listeners/
│   │   │   ├── Policies/
│   │   │   ├── Requests/
│   │   │   ├── Resources/
│   │   │   └── Routes/
│   │   │
│   │   ├── Wallet/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   ├── Repositories/
│   │   │   ├── Models/
│   │   │   ├── Events/
│   │   │   ├── Policies/
│   │   │   └── Routes/
│   │   │
│   │   ├── Order/
│   │   │   ├── Controllers/
│   │   │   │   ├── OrderController.php
│   │   │   │   ├── KitchenController.php
│   │   │   │   └── DigitalMenuController.php
│   │   │   ├── Services/
│   │   │   │   ├── OrderService.php
│   │   │   │   └── KitchenDisplayService.php
│   │   │   ├── Events/
│   │   │   │   ├── OrderCreated.php
│   │   │   │   └── OrderStatusUpdated.php
│   │   │   ├── Broadcasts/
│   │   │   │   ├── OrderCreatedBroadcast.php
│   │   │   │   └── OrderStatusBroadcast.php
│   │   │   └── Routes/
│   │   │
│   │   ├── Reservation/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   ├── Jobs/
│   │   │   │   └── SendReservationReminderJob.php
│   │   │   └── Routes/
│   │   │
│   │   ├── Delivery/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   │   ├── DeliveryService.php
│   │   │   │   ├── ShippingCalculatorService.php
│   │   │   │   └── DriverAssignmentService.php
│   │   │   └── Routes/
│   │   │
│   │   ├── CRM/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   └── Routes/
│   │   │
│   │   ├── WhatsApp/
│   │   │   ├── Controllers/
│   │   │   │   └── WebhookController.php
│   │   │   ├── Services/
│   │   │   │   └── WhatsAppService.php
│   │   │   ├── Jobs/
│   │   │   │   └── SendWhatsAppMessageJob.php
│   │   │   └── Routes/
│   │   │
│   │   ├── Report/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   │   ├── SalesReportService.php
│   │   │   │   ├── InventoryReportService.php
│   │   │   │   └── ProfitLossReportService.php
│   │   │   ├── Exports/
│   │   │   │   ├── SalesExport.php
│   │   │   │   └── InventoryExport.php
│   │   │   └── Routes/
│   │   │
│   │   ├── Dashboard/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   │   └── DashboardService.php
│   │   │   ├── Broadcasts/
│   │   │   └── Routes/
│   │   │
│   │   ├── Notification/
│   │   │   ├── Controllers/
│   │   │   ├── Services/
│   │   │   └── Channels/
│   │   │
│   │   └── Audit/
│   │       ├── Controllers/
│   │       ├── Services/
│   │       ├── Traits/
│   │       │   └── Auditable.php
│   │       └── Routes/
│   │
│   ├── Shared/                       # Shared kernel
│   │   ├── Contracts/
│   │   │   ├── RepositoryInterface.php
│   │   │   └── TenantAwareInterface.php
│   │   ├── Traits/
│   │   │   ├── BelongsToTenant.php
│   │   │   ├── HasUuid.php
│   │   │   └── Searchable.php
│   │   ├── Enums/
│   │   ├── Exceptions/
│   │   │   ├── TenantNotFoundException.php
│   │   │   ├── FeatureNotAvailableException.php
│   │   │   └── InsufficientStockException.php
│   │   ├── Middleware/
│   │   │   ├── ResolveTenant.php
│   │   │   ├── CheckSubscription.php
│   │   │   ├── CheckFeature.php
│   │   │   └── AuditRequest.php
│   │   ├── Scopes/
│   │   │   └── TenantScope.php
│   │   └── Repositories/
│   │       └── BaseRepository.php
│   │
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── Controller.php
│   │   ├── Middleware/
│   │   └── Kernel.php
│   │
│   ├── Providers/
│   │   ├── AppServiceProvider.php
│   │   ├── AuthServiceProvider.php
│   │   ├── EventServiceProvider.php
│   │   ├── RouteServiceProvider.php
│   │   ├── TenantServiceProvider.php
│   │   └── ModuleServiceProvider.php
│   │
│   └── Models/
│       └── User.php                  # Core user model
│
├── bootstrap/
│   ├── app.php
│   └── providers.php
│
├── config/
│   ├── app.php
│   ├── auth.php
│   ├── sanctum.php
│   ├── permission.php                # Spatie
│   ├── horizon.php
│   ├── reverb.php                    # WebSocket
│   ├── tenancy.php                   # Multi-tenant config
│   └── creativepos.php               # App-specific config
│
├── database/
│   ├── migrations/                   # 156 migration files
│   ├── seeders/
│   │   ├── DatabaseSeeder.php
│   │   ├── PackageSeeder.php
│   │   ├── PermissionSeeder.php
│   │   ├── RoleSeeder.php
│   │   └── DemoTenantSeeder.php
│   └── factories/                    # Model factories
│
├── routes/
│   ├── api.php                       # Main API router
│   ├── channels.php                  # WebSocket channels
│   ├── console.php
│   └── web.php
│
├── resources/
│   └── views/
│       └── receipts/                 # Receipt templates (PDF)
│
├── storage/
│   ├── app/
│   ├── framework/
│   └── logs/
│
└── tests/
    ├── Feature/
    │   ├── Auth/
    │   ├── POS/
    │   ├── Inventory/
    │   └── TenantIsolation/
    └── Unit/
        ├── Services/
        └── Repositories/
```

---

## Module Internal Pattern

Setiap module mengikuti struktur yang sama:

```
Module/
├── Controllers/     → HTTP handlers (thin, delegate to Service)
├── Services/        → Business logic (orchestration)
├── Repositories/    → Data access (Eloquent queries)
├── Models/          → Eloquent models + relationships
├── Events/          → Domain events
├── Listeners/       → Event handlers
├── Jobs/            → Async queue jobs
├── Policies/        → Authorization rules
├── Requests/        → Form validation
├── Resources/       → API response transformers
├── DTOs/            → Data transfer objects (optional)
├── Enums/           → Module-specific enums
├── Broadcasts/      → WebSocket broadcasts (if real-time)
└── Routes/
    └── api.php      → Module route definitions
```

---

## Key Design Patterns

### Repository Pattern

```php
// Contract
interface ProductRepositoryInterface {
    public function findByBarcode(string $barcode): ?Product;
    public function paginateWithFilters(array $filters): LengthAwarePaginator;
    public function createWithVariants(array $data): Product;
}

// Implementation
class ProductRepository extends BaseRepository implements ProductRepositoryInterface {
    public function __construct(Product $model) {
        parent::__construct($model);
    }
    // ...
}
```

### Service Pattern

```php
class TransactionService {
    public function __construct(
        private TransactionRepository $transactions,
        private StockService $stock,
        private PaymentService $payment,
        private DiscountService $discount,
    ) {}

    public function createTransaction(CreateTransactionDTO $dto): SaleTransaction {
        return DB::transaction(function () use ($dto) {
            $transaction = $this->transactions->create($dto);
            $this->discount->apply($transaction, $dto->discounts);
            $this->payment->process($transaction, $dto->payments);
            event(new SaleTransactionCompleted($transaction));
            return $transaction;
        });
    }
}
```

### Policy Pattern

```php
class SaleTransactionPolicy {
    public function void(User $user, SaleTransaction $transaction): bool {
        return $user->hasPermissionTo('pos.void')
            && $transaction->status === 'completed'
            && $transaction->tenant_id === tenant('id');
    }
}
```

---

## Route Registration

```php
// routes/api.php
Route::prefix('v1')->group(function () {
    // Public routes
    require app_path('Modules/Auth/Routes/api.php');

    // Authenticated routes
    Route::middleware(['auth:sanctum', 'tenant', 'subscription'])->group(function () {
        require app_path('Modules/Dashboard/Routes/api.php');
        require app_path('Modules/Inventory/Routes/api.php');
        require app_path('Modules/POS/Routes/api.php');
        require app_path('Modules/Loyalty/Routes/api.php');
        require app_path('Modules/Wallet/Routes/api.php');
        require app_path('Modules/Order/Routes/api.php');
        require app_path('Modules/Reservation/Routes/api.php');
        require app_path('Modules/Delivery/Routes/api.php');
        require app_path('Modules/CRM/Routes/api.php');
        require app_path('Modules/Report/Routes/api.php');
        require app_path('Modules/Tenant/Routes/api.php');
        require app_path('Modules/Audit/Routes/api.php');
    });

    // Platform (Super Admin)
    Route::middleware(['auth:sanctum', 'super-admin'])->prefix('platform')->group(function () {
        require app_path('Modules/Platform/Routes/api.php');
    });

    // Public QR Menu (no auth)
    Route::prefix('public')->group(function () {
        require app_path('Modules/Order/Routes/public.php');
    });
});
```

---

## Middleware Stack

| Middleware | Alias | Purpose |
|------------|-------|---------|
| `ResolveTenant` | `tenant` | Set tenant context from token/domain |
| `CheckSubscription` | `subscription` | Verify active subscription |
| `CheckFeature` | `feature:{key}` | Feature gating per package |
| `AuditRequest` | `audit` | Log request for audit trail |
| `SuperAdmin` | `super-admin` | Platform-level access only |
| `ThrottleRequests` | `throttle` | Rate limiting |

---

## Composer Dependencies (Key)

```json
{
    "require": {
        "php": "^8.4",
        "laravel/framework": "^12.0",
        "laravel/sanctum": "^4.0",
        "laravel/horizon": "^5.0",
        "laravel/reverb": "^1.0",
        "spatie/laravel-permission": "^6.0",
        "spatie/laravel-query-builder": "^6.0",
        "maatwebsite/excel": "^3.1",
        "barryvdh/laravel-dompdf": "^3.0",
        "predis/predis": "^2.0",
        "guzzlehttp/guzzle": "^7.0"
    }
}
```