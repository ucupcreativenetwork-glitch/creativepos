<?php

namespace App\Shared\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class AuditRequest
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if (in_array($request->method(), ['POST', 'PUT', 'PATCH', 'DELETE'], true)) {
            Log::channel('audit')->info('API request', [
                'user_id' => $request->user()?->id,
                'tenant_id' => tenant('id'),
                'method' => $request->method(),
                'path' => $request->path(),
                'ip' => $request->ip(),
                'status' => $response->getStatusCode(),
            ]);
        }

        return $response;
    }
}