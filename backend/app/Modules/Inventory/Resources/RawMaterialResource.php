<?php

namespace App\Modules\Inventory\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RawMaterialResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'unit' => $this->unit,
            'current_stock' => (float) $this->current_stock,
            'min_stock' => (float) $this->min_stock,
            'cost_per_unit' => (float) $this->cost_per_unit,
            'is_active' => $this->is_active,
            'is_low_stock' => $this->isLowStock(),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}