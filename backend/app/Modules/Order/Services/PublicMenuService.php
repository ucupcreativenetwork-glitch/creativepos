<?php

namespace App\Modules\Order\Services;

use App\Modules\Inventory\Models\Category;
use App\Modules\Inventory\Models\Product;
use App\Modules\Order\Models\DigitalMenuSetting;
use App\Modules\Order\Models\TableQrCode;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Tenant\Models\Outlet;

class PublicMenuService
{
    public function resolveTenant(string $tenantSlug): Tenant
    {
        $tenant = Tenant::query()->where('slug', $tenantSlug)->first();

        if (! $tenant || in_array($tenant->status, ['suspended', 'terminated'], true)) {
            abort(404, 'Bisnis tidak ditemukan.');
        }

        set_tenant($tenant);

        return $tenant;
    }

    public function resolveOutlet(string $outletSlug): Outlet
    {
        $outlet = Outlet::query()
            ->where(function ($q) use ($outletSlug) {
                $q->where('slug', $outletSlug)
                    ->orWhereRaw('LOWER(code) = ?', [strtolower($outletSlug)]);
            })
            ->where('is_active', true)
            ->first();

        if (! $outlet) {
            abort(404, 'Outlet tidak ditemukan.');
        }

        return $outlet;
    }

    public function getMenu(string $tenantSlug, string $outletSlug): array
    {
        $tenant = $this->resolveTenant($tenantSlug);
        $outlet = $this->resolveOutlet($outletSlug);

        return $this->buildMenuPayload($tenant, $outlet);
    }

    public function getTableMenu(string $tenantSlug, string $outletSlug, string $token): array
    {
        $payload = $this->getMenu($tenantSlug, $outletSlug);

        $qr = TableQrCode::query()
            ->with(['table.area'])
            ->where('qr_token', $token)
            ->where('is_active', true)
            ->first();

        if (! $qr) {
            abort(404, 'QR meja tidak valid.');
        }

        $payload['table'] = [
            'id' => $qr->table->id,
            'table_number' => $qr->table->table_number,
            'name' => $qr->table->name,
            'area' => $qr->table->area?->name,
        ];

        return $payload;
    }

    public function resolveTableByToken(string $token): ?TableQrCode
    {
        return TableQrCode::query()
            ->with('table')
            ->where('qr_token', $token)
            ->where('is_active', true)
            ->first();
    }

    protected function buildMenuPayload(Tenant $tenant, Outlet $outlet): array
    {
        $settings = DigitalMenuSetting::query()
            ->where(function ($q) use ($outlet) {
                $q->where('outlet_id', $outlet->id)->orWhereNull('outlet_id');
            })
            ->orderByDesc('outlet_id')
            ->first();

        $categories = Category::query()
            ->where('is_active', true)
            ->whereHas('products', fn ($q) => $q
                ->where('is_active', true)
                ->where('is_available', true)
                ->where('show_in_pos', true))
            ->orderBy('name')
            ->get(['id', 'name']);

        $products = Product::query()
            ->with('category:id,name')
            ->where('is_active', true)
            ->where('is_available', true)
            ->where('show_in_pos', true)
            ->orderBy('name')
            ->get();

        return [
            'tenant' => [
                'name' => $tenant->name,
                'slug' => $tenant->slug,
                'logo_url' => $tenant->logo_url,
            ],
            'outlet' => [
                'id' => $outlet->id,
                'name' => $outlet->name,
                'slug' => $outlet->slug ?? strtolower($outlet->code),
                'address' => $outlet->address,
            ],
            'settings' => [
                'theme_color' => $settings?->theme_color ?? '#2563EB',
                'welcome_message' => $settings?->welcome_message ?? 'Selamat menikmati hidangan kami!',
                'show_prices' => $settings?->show_prices ?? true,
                'allow_guest_order' => $settings?->allow_guest_order ?? true,
            ],
            'categories' => $categories,
            'products' => $products->map(fn ($p) => [
                'id' => $p->id,
                'name' => $p->name,
                'category_id' => $p->category_id,
                'category_name' => $p->category?->name,
                'base_price' => (float) $p->base_price,
                'description' => null,
            ]),
        ];
    }
}