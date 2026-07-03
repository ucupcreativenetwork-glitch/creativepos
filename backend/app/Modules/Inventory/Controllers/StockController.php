<?php

namespace App\Modules\Inventory\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventory\Requests\StockAdjustmentRequest;
use App\Modules\Inventory\Requests\StockImportRequest;
use App\Modules\Inventory\Requests\StockMovementRequest;
use App\Modules\Inventory\Resources\StockMovementResource;
use App\Modules\Inventory\Services\StockImportService;
use App\Modules\Inventory\Services\StockService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StockController extends Controller
{
    public function __construct(
        private readonly StockService $stockService,
        private readonly StockImportService $stockImportService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $paginator = $this->stockService->listStocks(
            $request->integer('warehouse_id') ?: null,
            $request->input('search'),
            $request->integer('per_page', 15),
        );

        $items = collect($paginator->items())->map(fn ($stock) => [
            'id' => $stock->id,
            'product' => [
                'id' => $stock->product?->id,
                'uuid' => $stock->product?->uuid,
                'name' => $stock->product?->name,
                'sku' => $stock->product?->sku,
                'min_stock' => $stock->product?->min_stock,
                'track_stock' => $stock->product?->track_stock,
            ],
            'warehouse' => [
                'id' => $stock->warehouse?->id,
                'name' => $stock->warehouse?->name,
                'code' => $stock->warehouse?->code,
            ],
            'quantity' => (float) $stock->quantity,
            'reserved_quantity' => (float) $stock->reserved_quantity,
            'is_low' => $stock->product?->track_stock
                && (float) $stock->quantity <= (int) ($stock->product?->min_stock ?? 0),
        ]);

        return ApiResponse::success($items, 'Operation successful', 200, [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'last_page' => $paginator->lastPage(),
        ]);
    }

    public function alerts(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $alerts = $this->stockService->alerts($request->integer('limit', 20));

        return ApiResponse::success($alerts->map(fn ($stock) => [
            'product' => [
                'id' => $stock->product?->id,
                'name' => $stock->product?->name,
                'sku' => $stock->product?->sku,
                'min_stock' => $stock->product?->min_stock,
            ],
            'warehouse' => [
                'id' => $stock->warehouse?->id,
                'name' => $stock->warehouse?->name,
                'code' => $stock->warehouse?->code,
            ],
            'quantity' => (float) $stock->quantity,
            'deficit' => max(0, (int) ($stock->product?->min_stock ?? 0) - (float) $stock->quantity),
        ]));
    }

    public function movements(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $paginator = $this->stockService->movements(
            $request->integer('product_id') ?: null,
            $request->integer('warehouse_id') ?: null,
            $request->integer('per_page', 20),
        );

        return ApiResponse::success(
            StockMovementResource::collection($paginator->items()),
            'Operation successful',
            200,
            [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        );
    }

    public function warehouses(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        return ApiResponse::success($this->stockService->warehouses());
    }

    public function stockIn(StockMovementRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.stock.adjust');

        $result = $this->stockService->stockIn(
            $request->integer('product_id'),
            $request->integer('warehouse_id'),
            (float) $request->input('quantity'),
            $request->input('notes'),
            $request->user()?->id,
        );

        return ApiResponse::created([
            'stock' => $result['stock'],
            'movement' => new StockMovementResource($result['movement']),
        ], 'Stok masuk berhasil dicatat.');
    }

    public function stockOut(StockMovementRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.stock.adjust');

        $result = $this->stockService->stockOut(
            $request->integer('product_id'),
            $request->integer('warehouse_id'),
            (float) $request->input('quantity'),
            $request->input('notes'),
            $request->user()?->id,
        );

        return ApiResponse::created([
            'stock' => $result['stock'],
            'movement' => new StockMovementResource($result['movement']),
        ], 'Stok keluar berhasil dicatat.');
    }

    public function adjustment(StockAdjustmentRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.stock.adjust');

        $result = $this->stockService->adjustment(
            $request->integer('product_id'),
            $request->integer('warehouse_id'),
            (float) $request->input('quantity'),
            $request->input('notes'),
            $request->user()?->id,
        );

        return ApiResponse::created([
            'stock' => $result['stock'],
            'movement' => new StockMovementResource($result['movement']),
        ], 'Penyesuaian stok berhasil.');
    }

    public function import(StockImportRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.stock.adjust');

        $result = $this->stockImportService->importFromFile(
            $request->file('file'),
            $request->integer('warehouse_id') ?: null,
            $request->user()?->id,
        );

        $message = "Import stok selesai: {$result['processed']} berhasil, {$result['skipped']} dilewati.";

        return ApiResponse::success($result, $message);
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses inventori.');
        }
    }
}