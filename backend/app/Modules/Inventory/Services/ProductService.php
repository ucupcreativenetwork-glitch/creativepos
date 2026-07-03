<?php

namespace App\Modules\Inventory\Services;

use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductModifier;
use App\Modules\Inventory\Models\ProductModifierGroup;
use App\Modules\Inventory\Repositories\ProductRepository;
use App\Modules\Inventory\Repositories\StockRepository;
use App\Shared\Services\PackageLimitService;
use App\Shared\Support\BarcodeGenerator;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class ProductService
{
    public function __construct(
        private readonly ProductRepository $repository,
        private readonly StockRepository $stockRepository,
        private readonly PackageLimitService $packageLimits,
    ) {}

    public function list(
        ?string $search = null,
        ?int $categoryId = null,
        ?bool $isActive = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->paginateFiltered($perPage, $search, $categoryId, $isActive);
    }

    public function findByUuid(string $uuid): Product
    {
        $product = $this->repository->findWithRelations($uuid);

        if (! $product) {
            abort(404, 'Produk tidak ditemukan.');
        }

        return $product;
    }

    public function findByBarcode(string $barcode): Product
    {
        $product = $this->repository->findByBarcode($barcode);

        if (! $product) {
            abort(404, 'Produk dengan barcode tersebut tidak ditemukan.');
        }

        return $product;
    }

    public function create(array $data, ?int $userId = null): Product
    {
        $this->packageLimits->assertCanCreateProduct();

        $initialStock = $data['initial_stock'] ?? null;
        $modifierGroups = $data['modifier_groups'] ?? null;
        unset($data['initial_stock'], $data['warehouse_id'], $data['modifier_groups']);

        $product = $this->repository->create($data);

        if (is_array($modifierGroups)) {
            $this->syncModifiers($product, $modifierGroups);
        }

        if ($product->track_stock && $initialStock > 0) {
            $warehouse = $this->stockRepository->defaultWarehouse();

            if ($warehouse) {
                app(StockService::class)->stockIn(
                    $product->id,
                    $warehouse->id,
                    (float) $initialStock,
                    'Stok awal produk',
                    $userId,
                );
            }
        }

        return $this->repository->findWithRelations($product->uuid);
    }

    public function update(Product $product, array $data): Product
    {
        $modifierGroups = $data['modifier_groups'] ?? null;
        unset($data['initial_stock'], $data['warehouse_id'], $data['modifier_groups']);

        $this->repository->update($product, $data);

        if (is_array($modifierGroups)) {
            $this->syncModifiers($product, $modifierGroups);
        }

        return $this->repository->findWithRelations($product->uuid);
    }

    public function syncModifiers(Product $product, array $groups): void
    {
        $keptGroupIds = [];

        foreach ($groups as $index => $groupData) {
            $group = null;

            if (! empty($groupData['id'])) {
                $group = ProductModifierGroup::query()
                    ->where('id', $groupData['id'])
                    ->where('product_id', $product->id)
                    ->first();
            }

            $attributes = [
                'tenant_id' => tenant('id'),
                'product_id' => $product->id,
                'name' => $groupData['name'],
                'is_required' => (bool) ($groupData['is_required'] ?? false),
                'min_select' => (int) ($groupData['min_select'] ?? 0),
                'max_select' => (int) ($groupData['max_select'] ?? 1),
                'sort_order' => (int) ($groupData['sort_order'] ?? $index),
            ];

            if ($group) {
                $group->update($attributes);
            } else {
                $group = ProductModifierGroup::query()->create($attributes);
            }

            $keptGroupIds[] = $group->id;
            $this->syncModifierItems($group, $groupData['modifiers'] ?? []);
        }

        $orphanGroups = ProductModifierGroup::query()
            ->where('product_id', $product->id)
            ->when($keptGroupIds !== [], fn ($q) => $q->whereNotIn('id', $keptGroupIds))
            ->get();

        foreach ($orphanGroups as $orphanGroup) {
            $orphanGroup->modifiers()->delete();
            $orphanGroup->delete();
        }
    }

    protected function syncModifierItems(ProductModifierGroup $group, array $modifiers): void
    {
        $keptModifierIds = [];

        foreach ($modifiers as $index => $modifierData) {
            $modifier = null;

            if (! empty($modifierData['id'])) {
                $modifier = ProductModifier::query()
                    ->where('id', $modifierData['id'])
                    ->where('group_id', $group->id)
                    ->first();
            }

            $attributes = [
                'tenant_id' => tenant('id'),
                'group_id' => $group->id,
                'name' => $modifierData['name'],
                'price_adjustment' => (float) ($modifierData['price_adjustment'] ?? 0),
                'is_default' => (bool) ($modifierData['is_default'] ?? false),
                'is_active' => (bool) ($modifierData['is_active'] ?? true),
                'sort_order' => (int) ($modifierData['sort_order'] ?? $index),
            ];

            if ($modifier) {
                $modifier->update($attributes);
            } else {
                $modifier = ProductModifier::query()->create($attributes);
            }

            $keptModifierIds[] = $modifier->id;
        }

        ProductModifier::query()
            ->where('group_id', $group->id)
            ->when($keptModifierIds !== [], fn ($q) => $q->whereNotIn('id', $keptModifierIds))
            ->delete();
    }

    public function generateBarcode(Product $product, bool $force = false): Product
    {
        if (! $force && filled($product->barcode)) {
            return $this->repository->findWithRelations($product->uuid);
        }

        $generator = app(BarcodeGenerator::class);
        $attempts = 0;

        do {
            $barcode = $attempts === 0
                ? $generator->generateForProduct($product)
                : $generator->withEan13CheckDigit(
                    str_pad((string) random_int(0, 999999999999), 12, '0', STR_PAD_LEFT)
                );
            $attempts++;
        } while (! $generator->isUniqueInTenant($barcode, $product->id) && $attempts < 8);

        if (! $generator->isUniqueInTenant($barcode, $product->id)) {
            abort(422, 'Gagal membuat barcode unik. Coba lagi.');
        }

        $this->repository->update($product, ['barcode' => $barcode]);

        return $this->repository->findWithRelations($product->uuid);
    }

    public function delete(Product $product): bool
    {
        return $this->repository->delete($product);
    }
}