<?php

namespace App\Shared\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckSubscription
{
    public function handle(Request $request, Closure $next): Response
    {
        $tenant = tenant();

        if ($tenant === null) {
            return $next($request);
        }

        $subscription = $tenant->activeSubscription;

        if ($subscription === null && ! in_array($tenant->status, ['trial', 'active'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'Your subscription is not active. Please renew to continue.',
            ], 403);
        }

        if ($tenant->status === 'trial' && $tenant->trial_ends_at?->isPast()) {
            return response()->json([
                'success' => false,
                'message' => 'Your trial period has expired. Please subscribe to continue.',
            ], 403);
        }

        return $next($request);
    }
}