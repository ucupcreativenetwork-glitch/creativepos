<?php

namespace App\Shared\Middleware;

use App\Modules\Tenant\Models\TenantSetting;
use App\Shared\Exceptions\FeatureNotAvailableException;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckFeature
{
    /** @var array<string, string> */
    private const TENANT_TOGGLE_MAP = [
        'reservation' => 'feature_reservations',
        'delivery' => 'feature_delivery',
    ];

    public function handle(Request $request, Closure $next, string $feature): Response
    {
        $tenant = tenant();

        if ($tenant === null) {
            return $next($request);
        }

        $subscription = $tenant->activeSubscription;
        $package = $subscription?->package ?? $tenant->trialPackage();

        if ($package === null || ! $package->hasFeature($feature)) {
            throw new FeatureNotAvailableException($feature);
        }

        if (isset(self::TENANT_TOGGLE_MAP[$feature])) {
            $settings = TenantSetting::query()
                ->where('tenant_id', $tenant->id)
                ->first();

            $toggleKey = self::TENANT_TOGGLE_MAP[$feature];
            $enabled = (bool) ($settings?->{$toggleKey} ?? true);

            if (! $enabled) {
                throw new FeatureNotAvailableException($feature);
            }
        }

        return $next($request);
    }
}