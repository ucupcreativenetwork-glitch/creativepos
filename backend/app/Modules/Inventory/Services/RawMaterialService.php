<?php

namespace App\Modules\Inventory\Services;

use App\Modules\Inventory\Models\RawMaterial;
use App\Modules\Inventory\Repositories\RawMaterialRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;

class RawMaterialService
{
    public function __construct(
        private readonly RawMaterialRepository $repository,
    ) {}

    public function list(
        ?string $search = null,
        ?bool $isActive = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->paginate($search, $isActive, $perPage);
    }

    public function find(int $id): RawMaterial
    {
        $material = $this->repository->find($id);

        if (! $material) {
            abort(404, 'Bahan baku tidak ditemukan.');
        }

        return $material;
    }

    public function create(array $data): RawMaterial
    {
        return $this->repository->create([
            'tenant_id' => tenant('id'),
            'name' => $data['name'],
            'unit' => $data['unit'],
            'current_stock' => (float) ($data['current_stock'] ?? 0),
            'min_stock' => (float) ($data['min_stock'] ?? 0),
            'cost_per_unit' => (float) ($data['cost_per_unit'] ?? 0),
            'is_active' => (bool) ($data['is_active'] ?? true),
        ]);
    }

    public function update(RawMaterial $material, array $data): RawMaterial
    {
        return $this->repository->update($material, $data);
    }

    public function delete(RawMaterial $material): bool
    {
        if ($material->recipes()->exists()) {
            abort(422, 'Bahan baku masih digunakan dalam resep produk.');
        }

        return $this->repository->delete($material);
    }

    public function lowStockAlerts(int $limit = 20): Collection
    {
        return $this->repository->lowStockAlerts($limit);
    }

    public function lowStockCount(): int
    {
        return $this->repository->lowStockCount();
    }

    public function stockIn(
        RawMaterial $material,
        float $quantity,
        ?string $notes = null,
    ): RawMaterial {
        if ($quantity <= 0) {
            abort(422, 'Jumlah stok masuk harus lebih dari 0.');
        }

        return DB::transaction(function () use ($material, $quantity, $notes) {
            $material->refresh();
            $material->current_stock = round((float) $material->current_stock + $quantity, 3);
            $material->save();

            return $material;
        });
    }

    public function stockOut(
        RawMaterial $material,
        float $quantity,
        ?string $notes = null,
        bool $allowInsufficient = false,
    ): RawMaterial {
        if ($quantity <= 0) {
            abort(422, 'Jumlah stok keluar harus lebih dari 0.');
        }

        return DB::transaction(function () use ($material, $quantity, $notes, $allowInsufficient) {
            $material->refresh();
            $before = (float) $material->current_stock;

            if (! $allowInsufficient && $quantity > $before) {
                abort(422, "Stok bahan baku {$material->name} tidak mencukupi (tersedia: {$before} {$material->unit}).");
            }

            $material->current_stock = round(max(0, $before - $quantity), 3);
            $material->save();

            return $material;
        });
    }
}