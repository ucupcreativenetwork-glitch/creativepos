<?php

namespace App\Shared\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePasswordChanged
{
    /**
     * @var list<string>
     */
    protected array $except = [
        'api/v1/auth/change-password',
        'api/v1/auth/logout',
        'api/v1/auth/me',
    ];

    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user?->must_change_password && ! $request->is($this->except)) {
            return response()->json([
                'success' => false,
                'message' => 'Anda harus mengganti kata sandi terlebih dahulu.',
                'code' => 'PASSWORD_CHANGE_REQUIRED',
            ], 403);
        }

        return $next($request);
    }
}