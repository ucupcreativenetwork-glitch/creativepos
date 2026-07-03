<?php

namespace App\Modules\Platform\Services;

use App\Modules\Platform\Models\Tenant;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class PlatformTenantService
{
    public function listTenants(?string $search, ?string $status, int $perPage = 15): LengthAwarePaginator
    {
        return Tenant::query()
            ->with('activeSubscription.package:id,name,slug')
            ->when($search, fn ($q) => $q->where(function ($inner) use ($search): void {
                $inner->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%")
                    ->orWhere('slug', 'like', "%{$search}%");
            }))
            ->when($status, fn ($q) => $q->where('status', $status))
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function suspend(Tenant $tenant): Tenant
    {
        $tenant->update([
            'status' => 'suspended',
            'suspended_at' => now(),
        ]);

        return $tenant->fresh();
    }

    public function activate(Tenant $tenant): Tenant
    {
        $tenant->update([
            'status' => 'active',
            'suspended_at' => null,
        ]);

        return $tenant->fresh();
    }
}