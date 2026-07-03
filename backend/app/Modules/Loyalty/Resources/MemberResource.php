<?php

namespace App\Modules\Loyalty\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MemberResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'member_code' => $this->member_code,
            'qr_token' => $this->qr_token,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'birthday' => $this->birthday?->format('Y-m-d'),
            'status' => $this->status,
            'total_spend' => (float) $this->total_spend,
            'visit_count' => (int) $this->visit_count,
            'last_visit_at' => $this->last_visit_at?->toIso8601String(),
            'tier' => $this->whenLoaded('tier', fn () => $this->tier ? [
                'id' => $this->tier->id,
                'name' => $this->tier->name,
                'slug' => $this->tier->slug,
                'point_multiplier' => (float) $this->tier->point_multiplier,
            ] : null),
            'points' => $this->whenLoaded('points', fn () => $this->points ? [
                'balance' => $this->points->balance,
                'lifetime_earned' => $this->points->lifetime_earned,
                'lifetime_redeemed' => $this->points->lifetime_redeemed,
            ] : null),
            'wallet' => $this->whenLoaded('wallet', fn () => $this->wallet ? [
                'balance' => (float) $this->wallet->balance,
                'lifetime_topup' => (float) $this->wallet->lifetime_topup,
                'lifetime_spent' => (float) $this->wallet->lifetime_spent,
                'status' => $this->wallet->status,
            ] : null),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}