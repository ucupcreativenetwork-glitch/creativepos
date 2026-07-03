<?php

namespace App\Modules\Order\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'order_number' => $this->order_number,
            'outlet' => $this->whenLoaded('outlet', fn () => [
                'id' => $this->outlet?->id,
                'name' => $this->outlet?->name,
                'code' => $this->outlet?->code,
            ]),
            'table' => $this->whenLoaded('table', fn () => $this->table ? [
                'id' => $this->table->id,
                'table_number' => $this->table->table_number,
                'name' => $this->table->name,
            ] : null),
            'source' => $this->source,
            'order_type' => $this->order_type,
            'status' => $this->status,
            'subtotal' => (float) $this->subtotal,
            'notes' => $this->notes,
            'items' => $this->whenLoaded('items', fn () => $this->items->map(fn ($item) => [
                'id' => $item->id,
                'product_id' => $item->product_id,
                'product_name' => $item->product_name,
                'quantity' => (float) $item->quantity,
                'unit_price' => (float) $item->unit_price,
                'subtotal' => (float) $item->subtotal,
                'notes' => $item->notes,
                'status' => $item->status,
            ])),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}