<?php

namespace App\Modules\Delivery\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeliveryZoneResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'name' => $this->name,
            'code' => $this->code,
            'description' => $this->description,
            'is_active' => $this->is_active,
            'outlet' => $this->whenLoaded('outlet', fn () => $this->outlet ? [
                'id' => $this->outlet->id,
                'name' => $this->outlet->name,
                'code' => $this->outlet->code,
            ] : null),
            'outlet_id' => $this->outlet_id,
            'base_fee' => $this->whenLoaded('rates', fn () => (float) ($this->rates->first()?->base_fee ?? 0)),
            'fee_per_km' => $this->whenLoaded('rates', fn () => (float) ($this->rates->first()?->fee_per_km ?? 0)),
            'max_distance_km' => $this->whenLoaded('rates', fn () => (float) ($this->rates->first()?->max_distance_km ?? 0)),
            'rates' => $this->whenLoaded('rates', fn () => $this->rates->map(fn ($rate) => [
                'id' => $rate->id,
                'min_distance_km' => (float) $rate->min_distance_km,
                'max_distance_km' => (float) $rate->max_distance_km,
                'base_fee' => (float) $rate->base_fee,
                'fee_per_km' => (float) $rate->fee_per_km,
            ])),
        ];
    }
}