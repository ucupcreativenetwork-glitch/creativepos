<?php

namespace App\Modules\Inventory\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductModifierGroupResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'is_required' => $this->is_required,
            'min_select' => (int) $this->min_select,
            'max_select' => (int) $this->max_select,
            'sort_order' => (int) $this->sort_order,
            'modifiers' => $this->whenLoaded('modifiers', fn () => $this->modifiers->map(fn ($modifier) => [
                'id' => $modifier->id,
                'name' => $modifier->name,
                'price_adjustment' => (float) $modifier->price_adjustment,
                'is_default' => $modifier->is_default,
                'is_active' => $modifier->is_active,
                'sort_order' => (int) $modifier->sort_order,
            ])),
        ];
    }
}