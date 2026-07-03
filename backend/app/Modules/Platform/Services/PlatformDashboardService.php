<?php

namespace App\Modules\Platform\Services;

use App\Modules\Platform\Models\Subscription;
use App\Modules\Platform\Models\Tenant;

class PlatformDashboardService
{
    public function getDashboard(): array
    {
        $activeSubscriptions = Subscription::query()
            ->withoutGlobalScopes()
            ->where('status', 'active')
            ->count();

        $tenantCount = Tenant::query()->count();
        $activeTenants = Tenant::query()->where('status', 'active')->count();
        $trialTenants = Tenant::query()->where('status', 'trial')->count();
        $suspendedTenants = Tenant::query()->where('status', 'suspended')->count();

        $mrr = $this->calculateMrr();

        $recentTenants = Tenant::query()
            ->with('activeSubscription.package:id,name,slug')
            ->latest()
            ->limit(5)
            ->get(['id', 'uuid', 'name', 'slug', 'status', 'created_at']);

        return [
            'total_tenants' => $tenantCount,
            'active_tenants' => $activeTenants,
            'trial_tenants' => $trialTenants,
            'suspended_tenants' => $suspendedTenants,
            'mrr' => $mrr,
            'arr' => round($mrr * 12, 2),
            'tenant_count' => $tenantCount,
            'active_subscriptions' => $activeSubscriptions,
            'recent_tenants' => $recentTenants->map(fn (Tenant $tenant) => [
                'id' => $tenant->id,
                'uuid' => $tenant->uuid,
                'name' => $tenant->name,
                'slug' => $tenant->slug,
                'status' => $tenant->status,
                'package' => $tenant->activeSubscription?->package?->only(['id', 'name', 'slug']),
                'created_at' => $tenant->created_at?->toIso8601String(),
            ])->values()->all(),
        ];
    }

    protected function calculateMrr(): float
    {
        return (float) Subscription::query()
            ->withoutGlobalScopes()
            ->join('packages', 'packages.id', '=', 'subscriptions.package_id')
            ->where('subscriptions.status', 'active')
            ->selectRaw('SUM(CASE
                WHEN subscriptions.billing_cycle = \'yearly\' THEN packages.price_yearly / 12
                ELSE packages.price_monthly
            END) as mrr')
            ->value('mrr');
    }
}