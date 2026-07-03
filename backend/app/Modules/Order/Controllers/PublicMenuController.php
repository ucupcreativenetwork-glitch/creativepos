<?php

namespace App\Modules\Order\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Order\Requests\PublicOrderRequest;
use App\Modules\Order\Resources\OrderResource;
use App\Modules\Order\Services\OrderService;
use App\Modules\Order\Services\PublicMenuService;
use App\Modules\Order\Services\TableServiceRequestService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PublicMenuController extends Controller
{
    public function __construct(
        private readonly PublicMenuService $menuService,
        private readonly OrderService $orderService,
        private readonly TableServiceRequestService $tableService,
    ) {}

    public function menu(string $tenantSlug, string $outletSlug): JsonResponse
    {
        return ApiResponse::success(
            $this->menuService->getMenu($tenantSlug, $outletSlug)
        );
    }

    public function tableMenu(string $tenantSlug, string $outletSlug, string $token): JsonResponse
    {
        return ApiResponse::success(
            $this->menuService->getTableMenu($tenantSlug, $outletSlug, $token)
        );
    }

    public function createOrder(PublicOrderRequest $request): JsonResponse
    {
        $this->menuService->resolveTenant($request->input('tenant_slug'));
        $outlet = $this->menuService->resolveOutlet($request->input('outlet_slug'));

        $settings = \App\Modules\Order\Models\DigitalMenuSetting::query()
            ->where(function ($q) use ($outlet) {
                $q->where('outlet_id', $outlet->id)->orWhereNull('outlet_id');
            })
            ->orderByDesc('outlet_id')
            ->first();

        if ($settings && ! $settings->allow_guest_order) {
            abort(403, 'Pemesanan tamu tidak diizinkan.');
        }

        $tableId = null;

        if ($token = $request->input('table_token')) {
            $qr = $this->menuService->resolveTableByToken($token);

            if (! $qr) {
                abort(404, 'Meja tidak valid.');
            }

            $tableId = $qr->table_id;
        }

        $order = $this->orderService->create([
            'outlet_id' => $outlet->id,
            'table_id' => $tableId,
            'source' => 'qr_menu',
            'order_type' => 'dine_in',
            'notes' => $request->input('notes'),
            'items' => $request->input('items'),
        ]);

        return ApiResponse::created(new OrderResource($order));
    }

    public function trackOrder(string $uuid): JsonResponse
    {
        $order = \App\Modules\Order\Models\Order::query()
            ->withoutGlobalScopes()
            ->with(['items', 'table'])
            ->where('uuid', $uuid)
            ->first();

        if (! $order) {
            abort(404, 'Pesanan tidak ditemukan.');
        }

        set_tenant(\App\Modules\Platform\Models\Tenant::query()->find($order->tenant_id));

        return ApiResponse::success([
            'uuid' => $order->uuid,
            'order_number' => $order->order_number,
            'status' => $order->status,
            'subtotal' => (float) $order->subtotal,
            'table' => $order->table ? [
                'table_number' => $order->table->table_number,
                'name' => $order->table->name,
            ] : null,
            'items' => $order->items->map(fn ($i) => [
                'product_name' => $i->product_name,
                'quantity' => (float) $i->quantity,
                'status' => $i->status,
            ]),
            'created_at' => $order->created_at?->toIso8601String(),
            'updated_at' => $order->updated_at?->toIso8601String(),
        ]);
    }

    public function callWaiter(Request $request): JsonResponse
    {
        $request->validate([
            'tenant_slug' => ['required', 'string'],
            'outlet_slug' => ['required', 'string'],
            'table_token' => ['required', 'string'],
        ]);

        $this->menuService->resolveTenant($request->input('tenant_slug'));
        $outlet = $this->menuService->resolveOutlet($request->input('outlet_slug'));
        $qr = $this->menuService->resolveTableByToken($request->input('table_token'));

        if (! $qr) {
            abort(404, 'Meja tidak valid.');
        }

        $record = $this->tableService->create('call_waiter', $qr, $outlet);

        return ApiResponse::success([
            'uuid' => $record->uuid,
            'type' => $record->type,
            'status' => $record->status,
        ], 'Pelayan telah dipanggil. Mohon tunggu sebentar.');
    }

    public function requestBill(Request $request): JsonResponse
    {
        $request->validate([
            'tenant_slug' => ['required', 'string'],
            'outlet_slug' => ['required', 'string'],
            'table_token' => ['required', 'string'],
        ]);

        $this->menuService->resolveTenant($request->input('tenant_slug'));
        $outlet = $this->menuService->resolveOutlet($request->input('outlet_slug'));
        $qr = $this->menuService->resolveTableByToken($request->input('table_token'));

        if (! $qr) {
            abort(404, 'Meja tidak valid.');
        }

        $record = $this->tableService->create('request_bill', $qr, $outlet);

        return ApiResponse::success([
            'uuid' => $record->uuid,
            'type' => $record->type,
            'status' => $record->status,
        ], 'Permintaan tagihan telah dikirim.');
    }
}