<?php

namespace Database\Seeders;

use App\Models\User;
use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductStock;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Platform\Models\Tenant;
use App\Modules\POS\Models\SaleTransaction;
use App\Modules\POS\Models\SaleTransactionItem;
use App\Modules\Tenant\Models\Outlet;
use App\Modules\Tenant\Models\TenantSetting;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class DashboardDemoSeeder extends Seeder
{
    public function run(): void
    {
        $tenants = Tenant::query()->get();

        foreach ($tenants as $tenant) {
            set_tenant($tenant);
            $this->seedForTenant($tenant);
        }
    }

    protected function seedForTenant(Tenant $tenant): void
    {
        if (Outlet::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        TenantSetting::query()->firstOrCreate(
            ['tenant_id' => $tenant->id],
            [
                'business_name' => $tenant->name,
                'setup_completed' => true,
            ]
        );

        $outlet = Outlet::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Outlet Utama',
            'code' => 'OUT01',
            'address' => 'Jl. Contoh No. 1',
            'is_default' => true,
            'is_active' => true,
        ]);

        $warehouseId = DB::table('warehouses')->insertGetId([
            'tenant_id' => $tenant->id,
            'outlet_id' => $outlet->id,
            'name' => 'Gudang Utama',
            'code' => 'WH01',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $categoryId = DB::table('categories')->insertGetId([
            'tenant_id' => $tenant->id,
            'uuid' => (string) Str::uuid(),
            'name' => 'Makanan',
            'slug' => 'makanan',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $products = [
            ['name' => 'Nasi Goreng Spesial', 'sku' => 'NGS-001', 'price' => 25000],
            ['name' => 'Es Teh Manis', 'sku' => 'ETM-001', 'price' => 8000],
            ['name' => 'Ayam Bakar', 'sku' => 'ABK-001', 'price' => 35000],
            ['name' => 'Mie Goreng', 'sku' => 'MGR-001', 'price' => 22000],
            ['name' => 'Kopi Susu', 'sku' => 'KPS-001', 'price' => 18000],
        ];

        $productIds = [];
        foreach ($products as $p) {
            $product = Product::query()->create([
                'tenant_id' => $tenant->id,
                'category_id' => $categoryId,
                'sku' => $p['sku'],
                'name' => $p['name'],
                'base_price' => $p['price'],
                'cost_price' => $p['price'] * 0.4,
                'min_stock' => 10,
                'track_stock' => true,
            ]);
            $productIds[] = $product->id;

            ProductStock::query()->create([
                'tenant_id' => $tenant->id,
                'product_id' => $product->id,
                'warehouse_id' => $warehouseId,
                'quantity' => rand(5, 100),
            ]);
        }

        $cashier = User::query()->where('tenant_id', $tenant->id)->first();
        if (! $cashier) {
            return;
        }

        for ($day = 6; $day >= 0; $day--) {
            $date = now()->subDays($day);
            $txCount = rand(3, 12);

            for ($i = 0; $i < $txCount; $i++) {
                $productIndex = array_rand($productIds);
                $product = Product::query()->find($productIds[$productIndex]);
                $qty = rand(1, 3);
                $subtotal = $product->base_price * $qty;

                $tx = SaleTransaction::query()->create([
                    'tenant_id' => $tenant->id,
                    'transaction_number' => 'TRX-'.$date->format('Ymd').'-'.str_pad((string) ($i + 1), 4, '0', STR_PAD_LEFT),
                    'outlet_id' => $outlet->id,
                    'cashier_id' => $cashier->id,
                    'order_type' => 'quick_sale',
                    'status' => 'completed',
                    'subtotal' => $subtotal,
                    'grand_total' => $subtotal,
                    'completed_at' => $date->copy()->setTime(rand(8, 21), rand(0, 59)),
                    'created_at' => $date,
                    'updated_at' => $date,
                ]);

                SaleTransactionItem::query()->create([
                    'tenant_id' => $tenant->id,
                    'transaction_id' => $tx->id,
                    'product_id' => $product->id,
                    'product_name' => $product->name,
                    'sku' => $product->sku,
                    'quantity' => $qty,
                    'unit_price' => $product->base_price,
                    'subtotal' => $subtotal,
                ]);
            }
        }

        for ($i = 0; $i < 5; $i++) {
            Member::query()->create([
                'tenant_id' => $tenant->id,
                'member_code' => 'MBR-'.str_pad((string) ($i + 1), 5, '0', STR_PAD_LEFT),
                'name' => 'Member Demo '.($i + 1),
                'phone' => '0812345678'.str_pad((string) $i, 2, '0', STR_PAD_LEFT),
                'status' => 'active',
            ]);
        }
    }
}