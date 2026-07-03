<?php

namespace App\Shared\Middleware;

use App\Modules\Platform\Models\Tenant;
use App\Shared\Exceptions\TenantNotFoundException;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ResolveTenant
{
    public function handle(Request $request, Closure $next): Response
    {
        $tenant = $this->resolveFromAuthenticatedUser($request)
            ?? $this->resolveFromSubdomain($request)
            ?? $this->resolveFromHeader($request);

        if ($tenant === null && $this->requiresTenant($request)) {
            throw new TenantNotFoundException('Unable to resolve tenant context.');
        }

        if ($tenant !== null) {
            if ($tenant->status === 'suspended' || $tenant->status === 'terminated') {
                throw new TenantNotFoundException('Tenant account is not active.');
            }

            set_tenant($tenant);
        }

        return $next($request);
    }

    protected function resolveFromAuthenticatedUser(Request $request): ?Tenant
    {
        $user = $request->user();

        if ($user === null || $user->is_super_admin || $user->tenant_id === null) {
            return null;
        }

        return Tenant::query()->find($user->tenant_id);
    }

    protected function resolveFromSubdomain(Request $request): ?Tenant
    {
        $host = $request->getHost();
        $suffix = config('creativepos.tenant.domain_suffix');

        if (! str_ends_with($host, $suffix)) {
            return null;
        }

        $subdomain = str_replace('.'.$suffix, '', $host);

        if ($subdomain === $host || in_array($subdomain, ['www', 'api', 'admin'], true)) {
            return null;
        }

        return Tenant::query()->where('slug', $subdomain)->first();
    }

    protected function resolveFromHeader(Request $request): ?Tenant
    {
        $header = config('creativepos.tenant.header');
        $tenantId = $request->header($header);

        if (blank($tenantId)) {
            return null;
        }

        if (is_numeric($tenantId)) {
            return Tenant::query()->find((int) $tenantId);
        }

        return Tenant::query()
            ->where('uuid', $tenantId)
            ->orWhere('slug', $tenantId)
            ->first();
    }

    protected function requiresTenant(Request $request): bool
    {
        return $request->user() !== null
            && ! $request->user()->is_super_admin
            && ! $request->routeIs('auth.*');
    }
}