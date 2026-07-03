<?php

namespace Tests;

use App\Models\Role;
use App\Models\User;
use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductStock;
use App\Modules\Inventory\Models\Warehouse;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Models\MemberPoint;
use App\Modules\Loyalty\Models\PointConfig;
use App\Modules\Platform\Models\Package;
use App\Modules\Platform\Models\Subscription;
use App\Modules\Platform\Models\Tenant;
use App\Modules\POS\Models\PaymentMethod;
use App\Modules\POS\Models\Shift;
use App\Modules\Tenant\Models\Outlet;
use App\Modules\Tenant\Models\TenantSetting;
use Database\Seeders\PackageSeeder;
use Database\Seeders\PaymentMethodSeeder;
use Database\Seeders\PermissionSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;

abstract class DatabaseTestCase extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seedCoreData();
    }

    protected function seedCoreData(): void
    {
        $this->seed([
            PermissionSeeder::class,
            RoleSeeder::class,
            PackageSeeder::class,
            PaymentMethodSeeder::class,
        ]);

        $this->ensurePosPaymentMethods();
    }

    protected function ensurePosPaymentMethods(): void
    {
        foreach ([
            ['code' => 'gopay', 'name' => 'GoPay', 'type' => 'e_wallet'],
            ['code' => 'ovo', 'name' => 'OVO', 'type' => 'e_wallet'],
            ['code' => 'transfer_bca', 'name' => 'Transfer BCA', 'type' => 'transfer'],
        ] as $method) {
            PaymentMethod::query()->updateOrCreate(
                ['code' => $method['code']],
                ['name' => $method['name'], 'type' => $method['type'], 'is_active' => true],
            );
        }
    }

    protected function createTenant(array $attrs = []): Tenant
    {
        $package = Package::query()->where('slug', 'starter')->firstOrFail();

        $tenant = Tenant::query()->create([
            'name' => $attrs['name'] ?? 'Test Business',
            'slug' => $attrs['slug'] ?? 'test-'.Str::lower(Str::random(8)),
            'email' => $attrs['email'] ?? 'tenant-'.Str::random(4).'@example.com',
            'phone' => $attrs['phone'] ?? '081234567890',
            'status' => $attrs['status'] ?? 'trial',
            'trial_ends_at' => $attrs['trial_ends_at'] ?? now()->addDays(14),
            'timezone' => $attrs['timezone'] ?? 'Asia/Jakarta',
            'currency' => 'IDR',
            'locale' => 'id',
        ]);

        Subscription::query()->create([
            'tenant_id' => $tenant->id,
            'package_id' => $package->id,
            'status' => $attrs['subscription_status'] ?? 'active',
            'billing_cycle' => 'monthly',
            'starts_at' => now()->toDateString(),
            'ends_at' => now()->addMonth()->toDateString(),
        ]);

        TenantSetting::query()->create([
            'tenant_id' => $tenant->id,
            'business_name' => $tenant->name,
            'setup_completed' => true,
            'tax_rate' => 0,
            'service_charge_rate' => 0,
            'enabled_payment_methods' => ['cash', 'gopay', 'ovo', 'transfer_bca'],
        ]);

        return $tenant;
    }

    protected function createUser(string $role = 'owner', ?Tenant $tenant = null, array $attrs = []): User
    {
        $tenant ??= $this->createTenant();
        set_tenant($tenant);

        $outlet = isset($attrs['outlet_id'])
            ? Outlet::query()->find($attrs['outlet_id'])
            : $this->createOutlet($tenant);

        $user = User::query()->create([
            'tenant_id' => $tenant->id,
            'name' => $attrs['name'] ?? 'Test User',
            'email' => $attrs['email'] ?? 'user-'.Str::random(6).'@example.com',
            'phone' => $attrs['phone'] ?? '0812'.random_int(10000000, 99999999),
            'password' => $attrs['password'] ?? 'password123',
            'status' => $attrs['status'] ?? 'active',
            'outlet_id' => $outlet->id,
        ]);

        $roleModel = Role::query()->where('name', $role)->firstOrFail();
        $user->assignRole($roleModel);

        return $user->fresh();
    }

    protected function createOutlet(?Tenant $tenant = null, array $attrs = []): Outlet
    {
        $tenant ??= tenant() ?? $this->createTenant();
        set_tenant($tenant);

        return Outlet::query()->firstOrCreate(
            [
                'tenant_id' => $tenant->id,
                'code' => $attrs['code'] ?? 'OUT01',
            ],
            [
                'name' => $attrs['name'] ?? 'Outlet Utama',
                'is_default' => $attrs['is_default'] ?? true,
                'is_active' => $attrs['is_active'] ?? true,
            ],
        );
    }

    protected function createWarehouse(?Tenant $tenant = null, ?Outlet $outlet = null): Warehouse
    {
        $tenant ??= tenant() ?? $this->createTenant();
        set_tenant($tenant);
        $outlet ??= $this->createOutlet($tenant);

        return Warehouse::query()->firstOrCreate(
            [
                'tenant_id' => $tenant->id,
                'code' => 'WH01',
            ],
            [
                'outlet_id' => $outlet->id,
                'name' => 'Gudang Utama',
                'is_active' => true,
            ],
        );
    }

    protected function createProduct(array $attrs = [], ?Tenant $tenant = null): Product
    {
        $tenant ??= tenant() ?? $this->createTenant();
        set_tenant($tenant);

        $outlet = Outlet::query()
            ->where('tenant_id', $tenant->id)
            ->first() ?? $this->createOutlet($tenant);
        $warehouse = $this->createWarehouse($tenant, $outlet);

        $product = Product::query()->create([
            'tenant_id' => $tenant->id,
            'name' => $attrs['name'] ?? 'Test Product',
            'sku' => $attrs['sku'] ?? 'SKU-'.Str::upper(Str::random(6)),
            'base_price' => $attrs['base_price'] ?? 50_000,
            'cost_price' => $attrs['cost_price'] ?? 0,
            'track_stock' => $attrs['track_stock'] ?? true,
            'show_in_pos' => $attrs['show_in_pos'] ?? true,
            'is_active' => $attrs['is_active'] ?? true,
            'is_available' => $attrs['is_available'] ?? true,
            'min_stock' => 0,
        ]);

        if ($product->track_stock) {
            ProductStock::query()->create([
                'tenant_id' => $tenant->id,
                'product_id' => $product->id,
                'warehouse_id' => $warehouse->id,
                'quantity' => $attrs['stock'] ?? 100,
            ]);
        }

        return $product->fresh();
    }

    protected function createMember(?Tenant $tenant = null, array $attrs = []): Member
    {
        $tenant ??= tenant() ?? $this->createTenant();
        set_tenant($tenant);

        PointConfig::query()->firstOrCreate(
            ['tenant_id' => $tenant->id],
            [
                'earn_amount' => 10_000,
                'earn_points' => 1,
                'redeem_points' => 100,
                'redeem_value' => 10_000,
                'min_redeem_points' => 100,
                'is_active' => true,
            ],
        );

        $member = Member::query()->create([
            'tenant_id' => $tenant->id,
            'member_code' => $attrs['member_code'] ?? 'MBR-'.Str::upper(Str::random(6)),
            'name' => $attrs['name'] ?? 'Member Test',
            'email' => $attrs['email'] ?? 'member-'.Str::random(4).'@example.com',
            'phone' => $attrs['phone'] ?? '0813'.random_int(10000000, 99999999),
            'status' => $attrs['status'] ?? 'active',
        ]);

        MemberPoint::query()->create([
            'tenant_id' => $tenant->id,
            'member_id' => $member->id,
            'balance' => $attrs['points_balance'] ?? 0,
        ]);

        return $member->fresh();
    }

    protected function openShift(User $user, ?Outlet $outlet = null, float $openingCash = 100_000): Shift
    {
        set_tenant(Tenant::query()->findOrFail($user->tenant_id));
        $outlet ??= Outlet::query()->findOrFail($user->outlet_id);

        return Shift::query()->create([
            'tenant_id' => $user->tenant_id,
            'outlet_id' => $outlet->id,
            'cashier_id' => $user->id,
            'shift_number' => 'SHF-TEST-'.Str::upper(Str::random(4)),
            'status' => 'open',
            'opening_cash' => $openingCash,
            'opened_at' => now(),
        ]);
    }

    protected function createInvoice(?Tenant $tenant = null, array $attrs = []): BillingInvoice
    {
        $tenant ??= tenant() ?? $this->createTenant();
        set_tenant($tenant);

        $subscription = Subscription::query()
            ->where('tenant_id', $tenant->id)
            ->firstOrFail();

        return BillingInvoice::query()->create([
            'tenant_id' => $tenant->id,
            'subscription_id' => $subscription->id,
            'invoice_number' => $attrs['invoice_number'] ?? 'INV-'.Str::upper(Str::random(8)),
            'amount' => $attrs['amount'] ?? 100_000,
            'tax_amount' => $attrs['tax_amount'] ?? 11_000,
            'total_amount' => $attrs['total_amount'] ?? 111_000,
            'status' => $attrs['status'] ?? 'sent',
            'due_date' => $attrs['due_date'] ?? now()->addDays(7)->toDateString(),
            'period_start' => now()->toDateString(),
            'period_end' => now()->addMonth()->toDateString(),
            'gateway_order_id' => $attrs['gateway_order_id'] ?? null,
        ]);
    }

    protected function actingAsTenantUser(?User $user = null, ?Tenant $tenant = null, string $role = 'cashier'): User
    {
        $tenant ??= $this->createTenant();
        set_tenant($tenant);
        $user ??= $this->createUser($role, $tenant);
        Sanctum::actingAs($user, ['*']);

        return $user;
    }

    protected function postTransaction(User $user, array $payload, ?string $idempotencyKey = null): \Illuminate\Testing\TestResponse
    {
        set_tenant(Tenant::query()->findOrFail($user->tenant_id));

        return $this->postJson('/api/v1/pos/transactions', $payload, [
            'X-Idempotency-Key' => $idempotencyKey ?? (string) Str::uuid(),
        ]);
    }

    protected function paymentMethodId(string $code): int
    {
        return PaymentMethod::query()->where('code', $code)->value('id');
    }
}