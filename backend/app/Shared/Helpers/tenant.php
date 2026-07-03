<?php

use App\Modules\Platform\Models\Tenant;

if (! function_exists('tenant')) {
    /**
     * Get the current tenant instance or a specific attribute.
     */
    function tenant(?string $key = null): mixed
    {
        $tenant = app()->bound('tenant') ? app('tenant') : null;

        if ($key === null) {
            return $tenant;
        }

        return $tenant instanceof Tenant ? $tenant->{$key} : null;
    }
}

if (! function_exists('set_tenant')) {
    /**
     * Set the current tenant context.
     */
    function set_tenant(?Tenant $tenant): void
    {
        if ($tenant === null) {
            app()->forgetInstance('tenant');

            return;
        }

        app()->instance('tenant', $tenant);
    }
}