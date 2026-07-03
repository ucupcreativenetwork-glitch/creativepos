<?php

namespace Database\Seeders;

use App\Models\Role;
use App\Models\User;
use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductStock;
use App\Modules\Inventory\Models\Warehouse;
use App\Modules\Platform\Models\Package;
use App\Modules\Platform\Models\Subscription;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Tenant\Models\Outlet;
use App\Modules\Tenant\Models\TenantSetting;
use App\Shared\Support\PaymentMethodCatalog;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DefaultAccountsSeeder extends Seeder
{
    public function run(): void
    {
        if (filter_var(env('SKIP_DEFAULT_ACCOUNTS', false), FILTER_VALIDATE_BOOLEAN)) {
            return;
        }

        $this->seedSuperAdmin();
        $this->seedDemoTenantWithAdmin();
    }

    protected function seedSuperAdmin(): void
    {
        $email = strtolower(env('CREATIVEPOS_SUPER_ADMIN_EMAIL', 'superadmin@creativepos.local'));
        $password = env('CREATIVEPOS_SUPER_ADMIN_PASSWORD', 'SuperAdmin123!');

        $user = User::query()
            ->where('email', $email)
            ->where('is_super_admin', true)
            ->orderByDesc('tenant_id')
            ->first();

        if ($user === null) {
            $user = User::query()->create([
                'tenant_id' => null,
                'name' => 'Super Admin',
                'email' => $email,
                'password' => Hash::make($password),
                'must_change_password' => true,
                'is_super_admin' => true,
                'status' => 'active',
                'email_verified_at' => now(),
            ]);
        } else {
            $user->update([
                'is_super_admin' => true,
                'status' => 'active',
                'password' => Hash::make($password),
                'must_change_password' => true,
            ]);
        }

    }

    protected function seedDemoTenantWithAdmin(): void
    {
        $adminEmail = strtolower(env('CREATIVEPOS_DEMO_ADMIN_EMAIL', 'admin@creativepos.local'));
        $adminPassword = env('CREATIVEPOS_DEMO_ADMIN_PASSWORD', 'Admin123!');

        $tenant = Tenant::query()->firstOrCreate(
            ['slug' => 'toko-demo'],
            [
                'name' => 'Toko Demo CreativePOS',
                'email' => $adminEmail,
                'phone' => '081234567890',
                'status' => 'active',
                'timezone' => 'Asia/Jakarta',
                'currency' => 'IDR',
                'locale' => 'id',
            ]
        );

        set_tenant($tenant);

        $package = Package::query()->where('slug', 'enterprise')->first()
            ?? Package::query()->where('slug', 'business')->first()
            ?? Package::query()->where('slug', 'starter')->first();

        if ($package !== null) {
            Subscription::query()->updateOrCreate(
                [
                    'tenant_id' => $tenant->id,
                    'package_id' => $package->id,
                ],
                [
                    'status' => 'active',
                    'billing_cycle' => 'yearly',
                    'starts_at' => now()->toDateString(),
                    'ends_at' => now()->addYear()->toDateString(),
                ]
            );
        }

        PaymentMethodCatalog::syncToDatabase();

        TenantSetting::query()->updateOrCreate(
            ['tenant_id' => $tenant->id],
            [
                'business_name' => $tenant->name,
                'setup_completed' => true,
                'enabled_payment_methods' => ['cash', 'qris', 'transfer_bca', 'gopay'],
                'feature_reservations' => true,
                'feature_delivery' => true,
                'feature_qr_menu' => true,
                'tax_rate' => 11,
                'service_charge_rate' => 5,
            ]
        );

        $outlet = Outlet::query()->firstOrCreate(
            [
                'tenant_id' => $tenant->id,
                'code' => 'OUT01',
            ],
            [
                'name' => 'Outlet Demo',
                'address' => 'Jl. Demo No. 1, Jakarta',
                'is_default' => true,
                'is_active' => true,
            ]
        );

        $warehouse = Warehouse::query()->firstOrCreate(
            [
                'tenant_id' => $tenant->id,
                'code' => 'WH01',
            ],
            [
                'outlet_id' => $outlet->id,
                'name' => 'Gudang Demo',
                'is_active' => true,
            ]
        );

        $this->seedDemoProducts($tenant, $warehouse);

        $admin = User::query()->firstOrCreate(
            [
                'email' => $adminEmail,
                'tenant_id' => $tenant->id,
            ],
            [
                'name' => 'Admin Toko',
                'phone' => '081234567890',
                'password' => Hash::make($adminPassword),
                'must_change_password' => true,
                'outlet_id' => $outlet->id,
                'is_super_admin' => false,
                'status' => 'active',
                'email_verified_at' => now(),
            ]
        );

        $admin->update([
            'password' => Hash::make($adminPassword),
            'must_change_password' => true,
            'status' => 'active',
            'outlet_id' => $outlet->id,
            'is_super_admin' => false,
        ]);

        $this->assignRole($admin, 'manager');

        $this->linkSuperAdminToDemoTenant($tenant, $outlet);
        $this->assignSuperAdminRole();
    }

    protected function linkSuperAdminToDemoTenant(Tenant $tenant, Outlet $outlet): void
    {
        $email = strtolower(env('CREATIVEPOS_SUPER_ADMIN_EMAIL', 'superadmin@creativepos.local'));

        $superAdmin = User::withTrashed()
            ->where('email', $email)
            ->where('is_super_admin', true)
            ->where('tenant_id', $tenant->id)
            ->first()
            ?? User::query()
                ->where('email', $email)
                ->where('is_super_admin', true)
                ->first();

        if ($superAdmin === null) {
            return;
        }

        if ($superAdmin->trashed()) {
            $superAdmin->restore();
        }

        User::withTrashed()
            ->where('email', $email)
            ->where('is_super_admin', true)
            ->where('id', '!=', $superAdmin->id)
            ->forceDelete();

        $superAdmin->update([
            'tenant_id' => $tenant->id,
            'outlet_id' => $outlet->id,
        ]);
    }

    protected function seedDemoProducts(Tenant $tenant, Warehouse $warehouse): void
    {
        if (Product::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        $categoryId = DB::table('categories')->insertGetId([
            'tenant_id' => $tenant->id,
            'uuid' => (string) Str::uuid(),
            'name' => 'Menu Demo',
            'slug' => 'menu-demo',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $products = [
            ['name' => 'Nasi Goreng Spesial', 'sku' => 'DEMO-NGS-001', 'price' => 25000],
            ['name' => 'Es Teh Manis', 'sku' => 'DEMO-ETM-001', 'price' => 8000],
            ['name' => 'Ayam Bakar', 'sku' => 'DEMO-ABK-001', 'price' => 35000],
            ['name' => 'Kopi Susu', 'sku' => 'DEMO-KPS-001', 'price' => 18000],
        ];

        foreach ($products as $item) {
            $product = Product::query()->create([
                'tenant_id' => $tenant->id,
                'category_id' => $categoryId,
                'sku' => $item['sku'],
                'name' => $item['name'],
                'base_price' => $item['price'],
                'cost_price' => $item['price'] * 0.4,
                'min_stock' => 5,
                'track_stock' => true,
                'is_active' => true,
                'is_available' => true,
                'show_in_pos' => true,
            ]);

            ProductStock::query()->create([
                'tenant_id' => $tenant->id,
                'product_id' => $product->id,
                'warehouse_id' => $warehouse->id,
                'quantity' => 50,
            ]);
        }
    }

    protected function assignSuperAdminRole(): void
    {
        $email = strtolower(env('CREATIVEPOS_SUPER_ADMIN_EMAIL', 'superadmin@creativepos.local'));

        $user = User::query()
            ->where('email', $email)
            ->where('is_super_admin', true)
            ->first();

        if ($user !== null && $user->tenant_id) {
            $this->assignRole($user, 'super-admin');
        }
    }

    protected function assignRole(User $user, string $roleName): void
    {
        $role = Role::query()
            ->where('name', $roleName)
            ->whereNull('tenant_id')
            ->first();

        if ($role === null || $user->tenant_id === null) {
            return;
        }

        setPermissionsTeamId($user->tenant_id);
        $user->syncRoles([$role]);
    }
}