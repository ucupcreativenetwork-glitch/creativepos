<?php

namespace App\Modules\Inventory\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductRecipeResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lineCost = (float) $this->quantity_needed * (float) ($this->rawMaterial?->cost_per_unit ?? 0);

        return [
            'id' => $this->id,
            'product_id' => $this->product_id,
            'raw_material_id' => $this->raw_material_id,
            'quantity_needed' => (float) $this->quantity_needed,
            'unit' => $this->unit,
            'notes' => $this->notes,
            'line_cost' => round($lineCost, 2),
            'raw_material' => $this->whenLoaded('rawMaterial', fn () => [
                'id' => $this->rawMaterial?->id,
                'name' => $this->rawMaterial?->name,
                'unit' => $this->rawMaterial?->unit,
                'cost_per_unit' => (float) ($this->rawMaterial?->cost_per_unit ?? 0),
                'current_stock' => (float) ($this->rawMaterial?->current_stock ?? 0),
            ]),
        ];
    }
}