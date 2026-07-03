<?php

namespace App\Modules\POS\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventory\Models\Category;
use App\Modules\Inventory\Models\Product;
use App\Modules\POS\Models\PaymentMethod;
use App\Modules\Tenant\Models\TenantSetting;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public function products(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $query = Product::query()
            ->with([
                'category:id,name',
                'modifierGroups' => fn ($q) => $q->orderBy('sort_order'),
                'modifierGroups.modifiers' => fn ($q) => $q
                    ->where('is_active', true)
                    ->orderBy('sort_order'),
            ])
            ->withSum('stocks as total_stock', 'quantity')
            ->where('is_active', true)
            ->where('is_available', true)
            ->where('show_in_pos', true);

        if ($search = $request->input('search')) {
            $query->search($search, ['name', 'sku', 'barcode']);
        }

        if ($categoryId = $request->integer('category_id')) {
            $query->where('category_id', $categoryId);
        }

        $products = $query->orderBy('name')->get();

        return ApiResponse::success($products->map(fn ($p) => [
            'id' => $p->id,
            'uuid' => $p->uuid,
            'name' => $p->name,
            'image_url' => $p->image_url,
            'sku' => $p->sku,
            'barcode' => $p->barcode,
            'base_price' => (float) $p->base_price,
            'category' => $p->category ? [
                'id' => $p->category->id,
                'name' => $p->category->name,
            ] : null,
            'total_stock' => (float) ($p->total_stock ?? 0),
            'track_stock' => $p->track_stock,
            'modifier_groups' => $p->modifierGroups->map(fn ($group) => [
                'id' => $group->id,
                'name' => $group->name,
                'is_required' => $group->is_required,
                'min_select' => (int) $group->min_select,
                'max_select' => (int) $group->max_select,
                'sort_order' => (int) $group->sort_order,
                'modifiers' => $group->modifiers->map(fn ($modifier) => [
                    'id' => $modifier->id,
                    'name' => $modifier->name,
                    'price_adjustment' => (float) $modifier->price_adjustment,
                    'is_default' => $modifier->is_default,
                    'sort_order' => (int) $modifier->sort_order,
                ])->values(),
            ])->values(),
        ]));
    }

    public function categories(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $categories = Category::query()
            ->where('is_active', true)
            ->whereHas('products', fn ($q) => $q
                ->where('is_active', true)
                ->where('show_in_pos', true))
            ->orderBy('name')
            ->get(['id', 'uuid', 'name']);

        return ApiResponse::success($categories);
    }

    public function paymentMethods(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $query = PaymentMethod::query()->where('is_active', true);

        $settings = TenantSetting::query()
            ->where('tenant_id', tenant('id'))
            ->first();

        if ($settings && filled($settings->enabled_payment_methods)) {
            $query->whereIn('code', $settings->enabled_payment_methods);
        }

        $methods = $query
            ->orderBy('name')
            ->get(['id', 'code', 'name', 'type']);

        return ApiResponse::success($methods);
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses POS.');
        }
    }
}