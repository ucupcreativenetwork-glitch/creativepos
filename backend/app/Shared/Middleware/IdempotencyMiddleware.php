<?php

namespace App\Shared\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class IdempotencyMiddleware
{
    protected const PROCESSING_TTL_MINUTES = 10;

    protected const SUCCESS_TTL_HOURS = 24;

    public function handle(Request $request, Closure $next): Response
    {
        $idempotencyKey = $request->header('X-Idempotency-Key');

        if (blank($idempotencyKey)) {
            return response()->json([
                'success' => false,
                'message' => 'Header X-Idempotency-Key wajib disertakan.',
            ], 400);
        }

        if (! Str::isUuid($idempotencyKey)) {
            return response()->json([
                'success' => false,
                'message' => 'X-Idempotency-Key harus berformat UUID v4 yang valid.',
            ], 400);
        }

        $user = $request->user();

        if ($user === null) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthenticated.',
            ], 401);
        }

        $cacheKey = $this->buildCacheKey($user->id, tenant('id'), $idempotencyKey);
        $existing = Cache::get($cacheKey);

        if (is_string($existing)) {
            $cached = json_decode($existing, true);

            if (is_array($cached)) {
                $resolved = $this->resolveCachedEntry($cached);

                if ($resolved !== null) {
                    return $resolved;
                }
            }
        }

        $processingPayload = json_encode([
            'status' => 'processing',
            'started_at' => now()->toIso8601String(),
        ]);

        if (! Cache::add($cacheKey, $processingPayload, now()->addMinutes(self::PROCESSING_TTL_MINUTES))) {
            $existing = Cache::get($cacheKey);

            if (is_string($existing)) {
                $cached = json_decode($existing, true);

                if (is_array($cached)) {
                    $resolved = $this->resolveCachedEntry($cached);

                    if ($resolved !== null) {
                        return $resolved;
                    }
                }
            }

            return response()->json([
                'success' => false,
                'message' => 'Permintaan dengan idempotency key yang sama sedang diproses. Silakan coba lagi.',
            ], 409);
        }

        try {
            $response = $next($request);
        } catch (\Throwable $e) {
            Cache::forget($cacheKey);

            throw $e;
        }

        if ($response->getStatusCode() >= 200 && $response->getStatusCode() < 300) {
            Cache::put(
                $cacheKey,
                json_encode([
                    'status' => 'success',
                    'status_code' => $response->getStatusCode(),
                    'body' => $response->getContent(),
                ]),
                now()->addHours(self::SUCCESS_TTL_HOURS),
            );
        } else {
            Cache::forget($cacheKey);
        }

        return $response;
    }

    protected function buildCacheKey(int $userId, mixed $tenantId, string $idempotencyKey): string
    {
        return sprintf(
            'idempotency:pos:%s:%d:%s',
            $tenantId ?? 'global',
            $userId,
            $idempotencyKey,
        );
    }

    protected function resolveCachedEntry(array $cached): ?Response
    {
        if (($cached['status'] ?? null) === 'success') {
            return response(
                $cached['body'] ?? '',
                (int) ($cached['status_code'] ?? 200),
                [
                    'Content-Type' => 'application/json',
                    'X-Idempotent-Replayed' => 'true',
                ],
            );
        }

        if (($cached['status'] ?? null) === 'processing') {
            return response()->json([
                'success' => false,
                'message' => 'Permintaan dengan idempotency key yang sama sedang diproses. Silakan coba lagi.',
            ], 409);
        }

        return null;
    }
}