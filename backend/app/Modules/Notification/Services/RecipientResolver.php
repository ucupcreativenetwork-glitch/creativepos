<?php

namespace App\Modules\Notification\Services;

use App\Models\User;
use App\Modules\Notification\Enums\NotificationEvent;
use Illuminate\Support\Collection;

class RecipientResolver
{
    /**
     * @return Collection<int, User>
     */
    public function resolve(NotificationEvent $event, ?int $outletId = null): Collection
    {
        $permissions = $event->defaultPermissions();

        $query = User::query()
            ->where('status', 'active')
            ->when(tenant('id'), fn ($q, $tenantId) => $q->where('tenant_id', $tenantId))
            ->where(function ($q) use ($permissions) {
                $q->where('is_super_admin', true);

                foreach ($permissions as $permission) {
                    $q->orWhereHas('permissions', fn ($pq) => $pq->where('name', $permission))
                        ->orWhereHas('roles.permissions', fn ($rq) => $rq->where('name', $permission));
                }
            });

        if ($outletId !== null) {
            $query->where(function ($q) use ($outletId) {
                $q->whereNull('outlet_id')->orWhere('outlet_id', $outletId);
            });
        }

        return $query->get()->unique('id');
    }
}