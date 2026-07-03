<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('user.{userId}', function ($user, int $userId): bool {
    return (int) $user->id === $userId;
});

Broadcast::channel('tenant.{tenantId}.outlet.{outletId}.kitchen', function ($user, int $tenantId): bool {
    return (int) $user->tenant_id === $tenantId;
});