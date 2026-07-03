<?php

namespace App\Modules\CRM\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TicketResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'ticket_number' => $this->ticket_number,
            'member' => $this->whenLoaded('member', fn () => $this->member ? [
                'id' => $this->member->id,
                'name' => $this->member->name,
                'member_code' => $this->member->member_code,
                'email' => $this->member->email,
                'phone' => $this->member->phone,
            ] : null),
            'customer_name' => $this->customer_name,
            'customer_email' => $this->customer_email,
            'customer_phone' => $this->customer_phone,
            'channel' => $this->channel,
            'subject' => $this->subject,
            'priority' => $this->priority,
            'status' => $this->status,
            'assignee' => $this->whenLoaded('assignee', fn () => $this->assignee ? [
                'id' => $this->assignee->id,
                'name' => $this->assignee->name,
                'email' => $this->assignee->email,
            ] : null),
            'sla_deadline' => $this->sla_deadline?->toIso8601String(),
            'first_response_at' => $this->first_response_at?->toIso8601String(),
            'resolved_at' => $this->resolved_at?->toIso8601String(),
            'closed_at' => $this->closed_at?->toIso8601String(),
            'rating' => $this->rating,
            'rating_comment' => $this->rating_comment,
            'messages' => $this->whenLoaded('messages', fn () => $this->messages->map(fn ($m) => [
                'id' => $m->id,
                'sender_type' => $m->sender_type,
                'sender' => $m->relationLoaded('sender') && $m->sender ? [
                    'id' => $m->sender->id,
                    'name' => $m->sender->name,
                ] : null,
                'message' => $m->message,
                'is_internal' => $m->is_internal,
                'created_at' => $m->created_at?->toIso8601String(),
            ])),
            'status_histories' => $this->whenLoaded('statusHistories', fn () => $this->statusHistories->map(fn ($h) => [
                'from_status' => $h->from_status,
                'to_status' => $h->to_status,
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