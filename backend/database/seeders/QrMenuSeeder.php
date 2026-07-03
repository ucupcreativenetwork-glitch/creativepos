<?php

namespace Database\Seeders;

use App\Modules\Inventory\Models\Product;
use App\Modules\Order\Models\DigitalMenuSetting;
use App\Modules\Order\Models\Table;
use App\Modules\Order\Models\TableArea;
use App\Modules\Order\Models\TableQrCode;
use App\Modules\Order\Services\OrderService;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Tenant\Models\Outlet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class QrMenuSeeder extends Seeder
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
        $outlet = Outlet::query()->where('tenant_id', $tenant->id)->first();

        if (! $outlet) {
            return;
        }

        if (! $outlet->slug) {
            $outlet->update(['slug' => strtolower($outlet->code)]);
        }

        DigitalMenuSetting::query()->firstOrCreate(
            ['tenant_id' => $tenant->id, 'outlet_id' => $outlet->id],
            [
                'theme_color' => '#2563EB',
                'welcome_message' => "Selamat datang di {$tenant->name}!",
                'show_prices' => true,
                'allow_guest_order' => true,
            ]
        );

        if (Table::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        $area = TableArea::query()->create([
            'tenant_id' => $tenant->id,
            'outlet_id' => $outlet->id,
            'name' => 'Area Utama',
            'sort_order' => 1,
            'is_active' => true,
        ]);

        $tables = [
            ['number' => 'T01', 'name' => 'Meja 1', 'capacity' => 4],
            ['number' => 'T02', 'name' => 'Meja 2', 'capacity' => 4],
            ['number' => 'T03', 'name' => 'Meja 3', 'capacity' => 6],
            ['number' => 'T04', 'name' => 'Meja 4', 'capacity' => 2],
        ];

        foreach ($tables as $t) {
            $table = Table::query()->create([
                'tenant_id' => $tenant->id,
                'outlet_id' => $outlet->id,
                'area_id' => $area->id,
                'table_number' => $t['number'],
                'name' => $t['name'],
                'capacity' => $t['capacity'],
                'status' => 'available',
                'is_active' => true,
            ]);

            TableQrCode::query()->create([
                'tenant_id' => $tenant->id,
                'table_id' => $table->id,
                'qr_token' => Str::random(24),
                'is_active' => true,
                'created_at' => now(),
            ]);
        }

        $products = Product::query()->limit(3)->get();

        if ($products->isNotEmpty()) {
            $orderService = app(OrderService::class);
            $orderService->create([
                'outlet_id' => $outlet->id,
                'table_id' => Table::query()->first()?->id,
                'source' => 'qr_menu',
                'order_type' => 'dine_in',
                'notes' => 'Pesanan demo QR Menu',
                'items' => $products->map(fn ($p) => [
                    'product_id' => $p->id,
                    'quantity' => 1,
                ])->all(),
            ]);
        }
    }
}