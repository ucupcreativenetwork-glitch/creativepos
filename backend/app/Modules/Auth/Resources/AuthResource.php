<?php

namespace App\Modules\Auth\Resources;

use App\Modules\Platform\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AuthResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        /** @var array $data */
        $data = $this->resource;

        return [
            'token' => $data['token'] ?? null,
            'requires_2fa' => $data['requires_2fa'] ?? false,
            'two_factor_method' => $data['two_factor_method'] ?? null,
            'pending_token' => $data['pending_token'] ?? null,
            'user' => isset($data['user'])
                ? new UserResource($data['user'])
                : null,
            'permissions' => $data['permissions'] ?? [],
            'roles' => $data['roles'] ?? [],
            'tenant' => isset($data['tenant']) && $data['tenant'] instanceof Tenant
                ? [
                    'id' => $data['tenant']->id,
                    'uuid' => $data['tenant']->uuid,
                    'name' => $data['tenant']->name,
                    'slug' => $data['tenant']->slug,
                    'status' => $data['tenant']->status,
                    'trial_ends_at' => $data['tenant']->trial_ends_at?->toIso8601String(),
                    'timezone' => $data['tenant']->timezone,
                    'currency' => $data['tenant']->currency,
                    'locale' => $data['tenant']->locale,
                ]
                : null,
        ];
    }
}