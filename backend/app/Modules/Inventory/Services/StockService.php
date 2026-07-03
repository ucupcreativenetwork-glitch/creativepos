<?php

namespace App\Modules\Inventory\Services;

use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\Warehouse;
use App\Modules\Inventory\Repositories\StockRepository;
use App\Modules\Notification\Services\StockAlertService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class StockService
{
    public function __construct(
        private readonly StockRepository $repository,
        private readonly StockAlertService $stockAlertService,
    ) {}

    public function listStocks(
        ?int $warehouseId = null,
        ?string $search = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->listStocks($warehouseId, $search, $perPage);
    }

    public function alerts(int $limit = 20): Collection
    {
        return $this->repository->lowStockAlerts($limit);
    }

    public function movements(
        ?int $productId = null,
        ?int $warehouseId = null,
        int $perPage = 20,
    ): LengthAwarePaginator {
        return $this->repository->movementHistory($productId, $warehouseId, $perPage);
    }

    public function warehouses(): Collection
    {
        return $this->repository->listWarehouses();
    }

    public function stockIn(
        int $productId,
        int $warehouseId,
        float $quantity,
        ?string $notes = null,
        ?int $userId = null,
    ): array {
        return $this->applyMovement($productId, $warehouseId, 'in', $quantity, $notes, $userId);
    }

    public function stockOut(
        int $productId,
        int $warehouseId,
        float $quantity,
        ?string $notes = null,
        ?int $userId = null,
    ): array {
        return $this->applyMovement($productId, $warehouseId, 'out', $quantity, $notes, $userId);
    }

    public function adjustment(
        int $productId,
        int $warehouseId,
        float $newQuantity,
        ?string $notes = null,
        ?int $userId = null,
    ): array {
        return DB::transaction(function () use ($productId, $warehouseId, $newQuantity, $notes, $userId) {
            $product = Product::query()->findOrFail($productId);
            $this->assertTrackStock($product);
            $this->assertWarehouseAccessible($warehouseId);

            $stock = $this->repository->findOrCreateStock($productId, $warehouseId);
            $before = (float) $stock->quantity;
            $delta = $newQuantity - $before;

            if ($delta < 0 && abs($delta) > $before) {
                abort(422, 'Stok tidak mencukupi untuk penyesuaian ini.');
            }

            $stock = $this->repository->updateStockQuantity($stock, $newQuantity);

            $movement = $this->repository->recordMovement([
                'tenant_id' => tenant('id'),
                'product_id' => $productId,
                'warehouse_id' => $warehouseId,
                'type' => 'adjustment',
                'quantity' => abs($delta),
                'before_quantity' => $before,
                'after_quantity' => $newQuantity,
                'notes' => $notes,
                'created_by' => $userId,
                'created_at' => now(),
            ]);

            $result = [
                'stock' => $stock->load('warehouse:id,name,code'),
                'movement' => $movement,
            ];

            $this->stockAlertService->checkProductStock($productId, $warehouseId);

            return $result;
        });
    }

    protected function applyMovement(
        int $productId,
        int $warehouseId,
        string $type,
        float $quantity,
        ?string $notes,
        ?int $userId,
    ): array {
        if ($quantity <= 0) {
            abort(422, 'Jumlah stok harus lebih dari 0.');
        }

        return DB::transaction(function () use ($productId, $warehouseId, $type, $quantity, $notes, $userId) {
            $product = Product::query()->findOrFail($productId);
            $this->assertTrackStock($product);
            $this->assertWarehouseAccessible($warehouseId);

            $stock = $this->repository->findOrCreateStock($productId, $warehouseId);
            $before = (float) $stock->quantity;

            if ($type === 'out' && $quantity > $before) {
                abort(422, 'Stok tidak mencukupi.');
            }

            $after = $type === 'in' ? $before + $quantity : $before - $quantity;
            $stock = $this->repository->updateStockQuantity($stock, $after);

            $movement = $this->repository->recordMovement([
                'tenant_id' => tenant('id'),
                'product_id' => $productId,
                'warehouse_id' => $warehouseId,
                'type' => $type,
                'quantity' => $quantity,
                'before_quantity' => $before,
                'after_quantity' => $after,
                'notes' => $notes,
                'created_by' => $userId,
                'created_at' => now(),
            ]);

            $result = [
                'stock' => $stock->load('warehouse:id,name,code'),
                'movement' => $movement,
            ];

            if ($type === 'out') {
                $this->stockAlertService->checkProductStock($productId, $warehouseId);
            }

            return $result;
        });
    }

    protected function assertTrackStock(Product $product): void
    {
        if (! $product->track_stock) {
            abort(422, 'Produk ini tidak melacak stok.');
        }
    }

    protected function assertWarehouseAccessible(int $warehouseId): void
    {
        $exists = Warehouse::query()
            ->where('id', $warehouseId)
            ->where('is_active', true)
            ->exists();

        if (! $exists) {
            abort(422, 'Gudang tidak valid atau tidak aktif.');
        }
    }
}