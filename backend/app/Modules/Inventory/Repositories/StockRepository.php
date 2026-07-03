<?php

namespace App\Modules\Inventory\Repositories;

use App\Modules\Inventory\Models\ProductStock;
use App\Modules\Inventory\Models\StockMovement;
use App\Modules\Inventory\Models\Warehouse;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class StockRepository
{
    public function listStocks(
        ?int $warehouseId = null,
        ?string $search = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        $query = ProductStock::query()
            ->with([
                'product:id,uuid,name,sku,min_stock,track_stock',
                'warehouse:id,name,code',
            ])
            ->whereHas('product', function ($q) use ($search): void {
                if ($search) {
                    $q->where(function ($inner) use ($search): void {
                        $inner->where('name', 'like', "%{$search}%")
                            ->orWhere('sku', 'like', "%{$search}%");
                    });
                }
            });

        if ($warehouseId) {
            $query->where('warehouse_id', $warehouseId);
        }

        return $query->orderByDesc('updated_at')->paginate($perPage);
    }

    public function lowStockAlerts(int $limit = 20): Collection
    {
        return ProductStock::query()
            ->with(['product:id,name,sku,min_stock,track_stock', 'warehouse:id,name,code'])
            ->whereHas('product', fn ($q) => $q->where('track_stock', true)->where('is_active', true))
            ->whereRaw('quantity <= (SELECT min_stock FROM products WHERE products.id = product_stocks.product_id)')
            ->orderBy('quantity')
            ->limit($limit)
            ->get();
    }

    public function movementHistory(
        ?int $productId = null,
        ?int $warehouseId = null,
        int $perPage = 20,
    ): LengthAwarePaginator {
        $query = StockMovement::query()
            ->with([
                'product:id,name,sku',
                'warehouse:id,name,code',
                'creator:id,name',
            ])
            ->orderByDesc('created_at');

        if ($productId) {
            $query->where('product_id', $productId);
        }

        if ($warehouseId) {
            $query->where('warehouse_id', $warehouseId);
        }

        return $query->paginate($perPage);
    }

    public function findOrCreateStock(int $productId, int $warehouseId): ProductStock
    {
        return ProductStock::query()->firstOrCreate(
            [
                'product_id' => $productId,
                'warehouse_id' => $warehouseId,
            ],
            [
                'tenant_id' => tenant('id'),
                'quantity' => 0,
                'reserved_quantity' => 0,
            ]
        );
    }

    public function recordMovement(array $data): StockMovement
    {
        return StockMovement::query()->create($data);
    }

    public function defaultWarehouse(): ?Warehouse
    {
        return Warehouse::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->first();
    }

    public function listWarehouses(): Collection
    {
        return Warehouse::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get(['id', 'name', 'code', 'outlet_id']);
    }

    public function updateStockQuantity(ProductStock $stock, float $quantity): ProductStock
    {
        $stock->update(['quantity' => $quantity]);

        return $stock->fresh();
    }

    public function totalStockForProduct(int $productId): float
    {
        return (float) ProductStock::query()
            ->where('product_id', $productId)
            ->sum('quantity');
    }
}