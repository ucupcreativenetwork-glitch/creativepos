<?php

namespace App\Modules\POS\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\POS\Models\HeldTransaction;
use App\Modules\POS\Services\HeldTransactionService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HeldTransactionController extends Controller
{
    public function __construct(
        private readonly HeldTransactionService $heldService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $held = $this->heldService->list($request->integer('outlet_id') ?: null);

        return ApiResponse::success(
            $held->map(fn (HeldTransaction $h) => $this->format($h))->all(),
        );
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $validated = $request->validate([
            'outlet_id' => ['required', 'integer', 'exists:outlets,id'],
            'reference_name' => ['required', 'string', 'max:100'],
            'table_id' => ['nullable', 'integer'],
            'member_id' => ['nullable', 'integer'],
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.quantity' => ['required', 'numeric', 'min:0.001'],
            'items.*.unit_price' => ['required', 'numeric', 'min:0'],
            'items.*.product_name' => ['nullable', 'string', 'max:200'],
            'items.*.sku' => ['nullable', 'string', 'max:100'],
            'items.*.modifiers' => ['sometimes', 'array'],
        ]);

        $held = $this->heldService->create($validated, $request->user());

        return ApiResponse::created($this->format($held), 'Transaksi ditahan');
    }

    public function resume(Request $request, HeldTransaction $held): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $payload = $this->heldService->resume($held);

        return ApiResponse::success($payload, 'Transaksi dilanjutkan');
    }

    public function destroy(Request $request, HeldTransaction $held): JsonResponse
    {
        $this->authorizePermission($request, 'pos.create');

        $this->heldService->delete($held);

        return ApiResponse::success(null, 'Transaksi ditahan dihapus');
    }

    protected function format(HeldTransaction $held): array
    {
        $held->loadMissing(['items.product:id,name,sku,base_price']);

        return [
            'id' => $held->id,
            'outlet_id' => $held->outlet_id,
            'reference_name' => $held->reference_name,
            'table_id' => $held->table_id,
            'member_id' => $held->member_id,
            'subtotal' => (float) $held->subtotal,
            'held_at' => $held->held_at?->toIso8601String(),
            'item_count' => $held->items->count(),
            'items' => $held->items->map(function ($item) {
                $meta = json_decode($item->notes ?? '{}', true) ?: [];

                return [
                    'product_id' => $item->product_id,
                    'product_name' => $meta['product_name'] ?? $item->product?->name,
                    'quantity' => (float) $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                ];
            })->all(),
        ];
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses POS.');
        }
    }
}