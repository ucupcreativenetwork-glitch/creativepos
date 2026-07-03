<?php

namespace App\Modules\POS\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'transaction_number' => $this->transaction_number,
            'outlet' => $this->whenLoaded('outlet', fn () => [
                'id' => $this->outlet?->id,
                'name' => $this->outlet?->name,
                'code' => $this->outlet?->code,
            ]),
            'cashier' => $this->whenLoaded('cashier', fn () => [
                'id' => $this->cashier?->id,
                'name' => $this->cashier?->name,
            ]),
            'order_type' => $this->order_type,
            'status' => $this->status,
            'subtotal' => (float) $this->subtotal,
            'discount_total' => (float) $this->discount_total,
            'tax_total' => (float) $this->tax_total,
            'service_charge' => (float) $this->service_charge,
            'grand_total' => (float) $this->grand_total,
            'notes' => $this->notes,
            'items' => $this->whenLoaded('items', fn () => $this->items->map(fn ($item) => [
                'id' => $item->id,
                'product_id' => $item->product_id,
                'product_name' => $item->product_name,
                'sku' => $item->sku,
                'quantity' => (float) $item->quantity,
                'unit_price' => (float) $item->unit_price,
                'modifiers' => $item->modifiers ?? [],
                'modifier_price_adjustment' => (float) ($item->modifier_price_adjustment ?? 0),
                'subtotal' => (float) $item->subtotal,
            ])),
            'payments' => $this->whenLoaded('payments', fn () => $this->payments->map(fn ($payment) => [
                'id' => $payment->id,
                'amount' => (float) $payment->amount,
                'reference_number' => $payment->reference_number,
                'payment_method' => $payment->relationLoaded('paymentMethod') ? [
                    'id' => $payment->paymentMethod?->id,
                    'name' => $payment->paymentMethod?->name,
                    'code' => $payment->paymentMethod?->code,
                    'type' => $payment->paymentMethod?->type,
                ] : null,
            ])),
            'completed_at' => $this->completed_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}