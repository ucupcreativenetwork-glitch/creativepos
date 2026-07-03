<?php

namespace App\Modules\Inventory\Repositories;

use App\Modules\Inventory\Models\RawMaterial;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;

class RawMaterialRepository
{
    public function paginate(
        ?string $search = null,
        ?bool $isActive = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        $query = RawMaterial::query()->orderBy('name');

        $query->search($search, ['name']);

        if ($isActive !== null) {
            $query->where('is_active', $isActive);
        }

        return $query->paginate($perPage);
    }

    public function find(int $id): ?RawMaterial
    {
        return RawMaterial::query()->find($id);
    }

    public function create(array $data): RawMaterial
    {
        return RawMaterial::query()->create($data);
    }

    public function update(RawMaterial $material, array $data): RawMaterial
    {
        $material->update($data);

        return $material->fresh();
    }

    public function delete(RawMaterial $material): bool
    {
        return (bool) $material->delete();
    }

    public function lowStockAlerts(int $limit = 20): Collection
    {
        return RawMaterial::query()
            ->where('is_active', true)
            ->whereColumn('current_stock', '<=', 'min_stock')
            ->orderBy('current_stock')
            ->limit($limit)
            ->get();
    }

    public function lowStockCount(): int
    {
        return RawMaterial::query()
            ->where('is_active', true)
            ->whereColumn('current_stock', '<=', 'min_stock')
            ->count();
    }
}