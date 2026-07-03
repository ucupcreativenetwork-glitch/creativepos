<?php

namespace App\Modules\Inventory\Repositories;

use App\Modules\Inventory\Models\Product;
use App\Shared\Repositories\BaseRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ProductRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct(new Product);
    }

    public function paginateFiltered(
        int $perPage = 15,
        ?string $search = null,
        ?int $categoryId = null,
        ?bool $isActive = null,
    ): LengthAwarePaginator {
        $query = $this->query()
            ->with(['category:id,name', 'stocks.warehouse:id,name,code'])
            ->withSum('stocks as total_stock', 'quantity');

        $query->search($search, ['name', 'sku', 'barcode']);

        if ($categoryId) {
            $query->where('category_id', $categoryId);
        }

        if ($isActive !== null) {
            $query->where('is_active', $isActive);
        }

        return $query->orderByDesc('created_at')->paginate($perPage);
    }

    public function findByBarcode(string $barcode): ?Product
    {
        return $this->query()
            ->with(['category:id,name', 'stocks.warehouse:id,name,code'])
            ->withSum('stocks as total_stock', 'quantity')
            ->where('barcode', $barcode)
            ->first();
    }

    public function findWithRelations(string $uuid): ?Product
    {
        return $this->query()
            ->with([
                'category:id,name,uuid',
                'stocks.warehouse:id,name,code',
                'modifierGroups.modifiers' => fn ($q) => $q->orderBy('sort_order'),
                'recipes.rawMaterial:id,name,unit,cost_per_unit,current_stock',
            ])
            ->withSum('stocks as total_stock', 'quantity')
            ->where('uuid', $uuid)
            ->first();
    }
}