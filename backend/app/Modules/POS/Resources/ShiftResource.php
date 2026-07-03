<?php

namespace App\Modules\POS\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ShiftResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'shift_number' => $this->shift_number,
            'status' => $this->status,
            'opening_cash' => (float) $this->opening_cash,
            'closing_cash' => $this->closing_cash !== null ? (float) $this->closing_cash : null,
            'expected_cash' => $this->expected_cash !== null ? (float) $this->expected_cash : null,
            'cash_difference' => $this->cash_difference !== null ? (float) $this->cash_difference : null,
            'total_sales' => (float) $this->total_sales,
            'total_transactions' => (int) $this->total_transactions,
            'outlet' => $this->whenLoaded('outlet', fn () => [
                'id' => $this->outlet?->id,
                'name' => $this->outlet?->name,
                'code' => $this->outlet?->code,
            ]),
            'cashier' => $this->whenLoaded('cashier', fn () => [
                'id' => $this->cashier?->id,
                'name' => $this->cashier?->name,
            ]),
            'opened_at' => $this->opened_at?->toIso8601String(),
            'closed_at' => $this->closed_at?->toIso8601String(),
            'notes' => $this->notes,
        ];
    }
}