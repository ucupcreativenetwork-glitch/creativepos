<?php

namespace App\Modules\Inventory\Services;

use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductRecipe;
use App\Modules\Inventory\Models\RawMaterial;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class RecipeService
{
    public function __construct(
        private readonly RawMaterialService $rawMaterialService,
    ) {}

    public function getRecipe(Product $product): Collection
    {
        return $product->recipes()
            ->with('rawMaterial:id,name,unit,cost_per_unit,current_stock')
            ->orderBy('id')
            ->get();
    }

    public function syncRecipe(Product $product, array $ingredients): Collection
    {
        return DB::transaction(function () use ($product, $ingredients) {
            $keptIds = [];

            foreach ($ingredients as $ingredient) {
                $rawMaterial = RawMaterial::query()
                    ->where('id', $ingredient['raw_material_id'])
                    ->where('is_active', true)
                    ->first();

                if (! $rawMaterial) {
                    abort(422, 'Bahan baku tidak valid atau tidak aktif.');
                }

                $unit = $ingredient['unit'] ?? $rawMaterial->unit;

                if ($unit !== $rawMaterial->unit) {
                    abort(422, "Satuan {$unit} tidak sesuai dengan satuan bahan baku {$rawMaterial->name} ({$rawMaterial->unit}).");
                }

                $recipe = null;

                if (! empty($ingredient['id'])) {
                    $recipe = ProductRecipe::query()
                        ->where('id', $ingredient['id'])
                        ->where('product_id', $product->id)
                        ->first();
                }

                $attributes = [
                    'tenant_id' => tenant('id'),
                    'product_id' => $product->id,
                    'raw_material_id' => $rawMaterial->id,
                    'quantity_needed' => (float) $ingredient['quantity_needed'],
                    'unit' => $unit,
                    'notes' => $ingredient['notes'] ?? null,
                ];

                if ($recipe) {
                    $recipe->update($attributes);
                } else {
                    $recipe = ProductRecipe::query()->create($attributes);
                }

                $keptIds[] = $recipe->id;
            }

            ProductRecipe::query()
                ->where('product_id', $product->id)
                ->when($keptIds !== [], fn ($q) => $q->whereNotIn('id', $keptIds))
                ->delete();

            return $this->getRecipe($product);
        });
    }

    public function calculateCOGS(Product $product): float
    {
        $recipes = $product->recipes()
            ->with('rawMaterial:id,cost_per_unit')
            ->get();

        if ($recipes->isEmpty()) {
            return 0.0;
        }

        return round(
            $recipes->sum(fn (ProductRecipe $recipe) => (float) $recipe->quantity_needed * (float) $recipe->rawMaterial->cost_per_unit),
            2,
        );
    }

    public function consumeForSale(int $productId, float $quantitySold): void
    {
        if ($quantitySold <= 0) {
            return;
        }

        $recipes = ProductRecipe::query()
            ->with('rawMaterial')
            ->where('product_id', $productId)
            ->get();

        if ($recipes->isEmpty()) {
            return;
        }

        foreach ($recipes as $recipe) {
            $needed = round((float) $recipe->quantity_needed * $quantitySold, 3);

            if ($needed <= 0) {
                continue;
            }

            $this->rawMaterialService->stockOut(
                $recipe->rawMaterial,
                $needed,
                "Penjualan produk #{$productId}",
            );
        }
    }

    public function restoreForVoid(int $productId, float $quantitySold): void
    {
        if ($quantitySold <= 0) {
            return;
        }

        $recipes = ProductRecipe::query()
            ->with('rawMaterial')
            ->where('product_id', $productId)
            ->get();

        foreach ($recipes as $recipe) {
            $restoreQty = round((float) $recipe->quantity_needed * $quantitySold, 3);

            if ($restoreQty <= 0) {
                continue;
            }

            $this->rawMaterialService->stockIn(
                $recipe->rawMaterial,
                $restoreQty,
                "Void transaksi produk #{$productId}",
            );
        }
    }
}