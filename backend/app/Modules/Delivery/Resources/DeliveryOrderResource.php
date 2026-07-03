<?php

namespace App\Modules\Delivery\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DeliveryOrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'delivery_number' => $this->delivery_number,
            'outlet_id' => $this->outlet_id,
            'driver_id' => $this->driver_id,
            'outlet' => $this->whenLoaded('outlet', fn () => [
                'id' => $this->outlet?->id,
                'name' => $this->outlet?->name,
                'code' => $this->outlet?->code,
            ]),
            'driver' => $this->whenLoaded('driver', fn () => $this->driver ? [
                'id' => $this->driver->id,
                'uuid' => $this->driver->uuid,
                'vehicle_type' => $this->driver->vehicle_type,
                'vehicle_plate' => $this->driver->vehicle_plate,
                'user' => $this->driver->relationLoaded('user') && $this->driver->user ? [
                    'id' => $this->driver->user->id,
                    'name' => $this->driver->user->name,
                    'phone' => $this->driver->user->phone,
                ] : null,
            ] : null),
            'member' => $this->whenLoaded('member', fn () => $this->member ? [
                'id' => $this->member->id,
                'name' => $this->member->name,
                'member_code' => $this->member->member_code,
            ] : null),
            'zone' => $this->whenLoaded('zone', fn () => $this->zone ? [
                'id' => $this->zone->id,
                'uuid' => $this->zone->uuid,
                'name' => $this->zone->name,
                'code' => $this->zone->code,
            ] : null),
            'customer_name' => $this->customer_name,
            'customer_phone' => $this->customer_phone,
            'address' => [
                'recipient_name' => $this->customer_name,
                'phone' => $this->customer_phone,
                'address' => $this->delivery_address,
            ],
            'delivery_address' => $this->delivery_address,
            'delivery_city' => $this->delivery_city,
            'delivery_notes' => $this->delivery_notes,
            'status' => $this->status,
            'subtotal' => (float) $this->subtotal,
            'shipping_fee' => (float) $this->shipping_fee,
            'total_amount' => (float) $this->total_amount,
            'grand_total' => (float) $this->total_amount,
            'distance_km' => $this->distance_km !== null ? (float) $this->distance_km : null,
            'estimated_minutes' => $this->estimated_minutes,
            'assigned_at' => $this->assigned_at?->toIso8601String(),
            'picked_up_at' => $this->picked_up_at?->toIso8601String(),
            'delivered_at' => $this->delivered_at?->toIso8601String(),
            'items' => $this->whenLoaded('items', fn () => $this->items->map(fn ($item) => [
                'id' => $item->id,
                'product_id' => $item->product_id,
                'product_name' => $item->product_name,
                'quantity' => (float) $item->quantity,
                'unit_price' => (float) $item->unit_price,
                'subtotal' => (float) $item->subtotal,
                'notes' => $item->notes,
            ])),
            'tracking_points' => $this->whenLoaded('trackingPoints', fn () => $this->trackingPoints->map(fn ($p) => [
                'latitude' => (float) $p->latitude,
                'longitude' => (float) $p->longitude,
                'recorded_at' => $p->recorded_at?->toIso8601String(),
            ])),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}