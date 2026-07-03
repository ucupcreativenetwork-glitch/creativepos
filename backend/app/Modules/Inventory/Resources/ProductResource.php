<?php

namespace App\Modules\Inventory\Resources;

use App\Modules\Inventory\Services\RecipeService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'name' => $this->name,
            'image_url' => $this->image_url,
            'sku' => $this->sku,
            'barcode' => $this->barcode,
            'category' => $this->whenLoaded('category', fn () => [
                'id' => $this->category?->id,
                'name' => $this->category?->name,
                'uuid' => $this->category?->uuid,
            ]),
            'base_price' => (float) $this->base_price,
            'cost_price' => (float) $this->cost_price,
            'min_stock' => (int) $this->min_stock,
            'track_stock' => $this->track_stock,
            'is_active' => $this->is_active,
            'is_available' => $this->is_available,
            'show_in_pos' => $this->show_in_pos,
            'total_stock' => (float) ($this->total_stock ?? 0),
            'modifier_groups' => $this->whenLoaded('modifierGroups', fn () => ProductModifierGroupResource::collection($this->modifierGroups)),
            'recipe' => $this->whenLoaded('recipes', fn () => ProductRecipeResource::collection($this->recipes)),
            'cogs' => $this->when(
                $this->relationLoaded('recipes'),
                fn () => app(RecipeService::class)->calculateCOGS($this->resource),
            ),
            'stocks' => $this->whenLoaded('stocks', fn () => $this->stocks->map(fn ($stock) => [
                'warehouse_id' => $stock->warehouse_id,
                'warehouse' => $stock->warehouse ? [
                    'id' => $stock->warehouse->id,
                    'name' => $stock->warehouse->name,
                    'code' => $stock->warehouse->code,
                ] : null,
                'quantity' => (float) $stock->quantity,
                'reserved_quantity' => (float) $stock->reserved_quantity,
            ])),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}