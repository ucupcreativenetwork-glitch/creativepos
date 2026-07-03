<?php

namespace App\Modules\Auth\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'uuid' => $this->uuid,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone,
            'avatar_url' => $this->avatar_url,
            'status' => $this->status,
            'is_super_admin' => $this->is_super_admin,
            'two_factor_enabled' => $this->two_factor_enabled,
            'two_factor_method' => $this->two_factor_method,
            'email_verified_at' => $this->email_verified_at?->toIso8601String(),
            'last_login_at' => $this->last_login_at?->toIso8601String(),
            'roles' => $this->whenLoaded('roles', fn () => $this->getRoleNames()->toArray(), $this->getRoleNames()->toArray()),
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}