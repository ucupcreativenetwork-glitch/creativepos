<?php

namespace App\Modules\Delivery\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeliveryDriverResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'name' => $this->relationLoaded('user') ? $this->user?->name : null,
            'phone' => $this->relationLoaded('user') ? $this->user?->phone : null,
            'type' => 'internal',
            'vehicle_type' => $this->vehicle_type,
            'vehicle_plate' => $this->vehicle_plate,
            'is_active' => $this->is_active,
            'is_available' => $this->is_available,
            'user' => $this->whenLoaded('user', fn () => $this->user ? [
                'id' => $this->user->id,
                'name' => $this->user->name,
                'phone' => $this->user->phone,
                'email' => $this->user->email,
            ] : null),
            'outlet' => $this->whenLoaded('outlet', fn () => $this->outlet ? [
                'id' => $this->outlet->id,
                'name' => $this->outlet->name,
                'code' => $this->outlet->code,
            ] : null),
        ];
    }
}