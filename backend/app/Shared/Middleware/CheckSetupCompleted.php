<?php

namespace App\Shared\Middleware;

use App\Modules\Tenant\Models\TenantSetting;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckSetupCompleted
{
    protected array $exemptPrefixes = [
        'api/v1/settings',
        'api/v1/auth',
        'api/v1/health',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if (! $this->shouldAnnotate($request, $response)) {
            return $response;
        }

        $settings = TenantSetting::query()
            ->where('tenant_id', tenant('id'))
            ->first();

        if ($settings?->setup_completed) {
            return $response;
        }

        $payload = $response->getData(true);

        if (! is_array($payload)) {
            return $response;
        }

        $payload['needs_onboarding'] = true;
        $response->setData($payload);

        return $response;
    }

    protected function shouldAnnotate(Request $request, Response $response): bool
    {
        if (! $response instanceof JsonResponse) {
            return false;
        }

        if ($request->user() === null || tenant('id') === null) {
            return false;
        }

        if ($request->user()->is_super_admin) {
            return false;
        }

        $path = trim($request->path(), '/');

        foreach ($this->exemptPrefixes as $prefix) {
            if (str_starts_with($path, $prefix)) {
                return false;
            }
        }

        return true;
    }
}