<?php

namespace App\Modules\Reservation\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReservationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'reservation_number' => $this->reservation_number,
            'outlet' => $this->whenLoaded('outlet', fn () => [
                'id' => $this->outlet?->id,
                'name' => $this->outlet?->name,
                'code' => $this->outlet?->code,
            ]),
            'member' => $this->whenLoaded('member', fn () => $this->member ? [
                'id' => $this->member->id,
                'name' => $this->member->name,
                'member_code' => $this->member->member_code,
            ] : null),
            'table' => $this->whenLoaded('table', fn () => $this->table ? [
                'id' => $this->table->id,
                'table_number' => $this->table->table_number,
                'name' => $this->table->name,
            ] : null),
            'customer_name' => $this->customer_name,
            'customer_phone' => $this->customer_phone,
            'customer_email' => $this->customer_email,
            'guest_count' => $this->guest_count,
            'reservation_date' => $this->reservation_date?->toDateString(),
            'reservation_time' => substr((string) $this->reservation_time, 0, 5),
            'status' => $this->status,
            'notes' => $this->notes,
            'confirmed_at' => $this->confirmed_at?->toIso8601String(),
            'arrived_at' => $this->arrived_at?->toIso8601String(),
            'cancelled_at' => $this->cancelled_at?->toIso8601String(),
            'status_histories' => $this->whenLoaded('statusHistories', fn () => $this->statusHistories->map(fn ($h) => [
                'from_status' => $h->from_status,
                'to_status' => $h->to_status,
                'notes' => $h->notes,
                'changed_by' => $h->relationLoaded('changer') && $h->changer ? [
                    'id' => $h->changer->id,
                    'name' => $h->changer->name,
                ] : null,
                'created_at' => $h->created_at?->toIso8601String(),
            ])),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}