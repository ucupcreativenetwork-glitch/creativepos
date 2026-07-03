<?php

namespace App\Modules\Loyalty\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Loyalty\Models\PointConfig;
use App\Modules\Loyalty\Services\LoyaltyBootstrapService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PointConfigController extends Controller
{
    public function __construct(
        private readonly LoyaltyBootstrapService $bootstrapService,
    ) {}

    public function show(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.view');

        $config = PointConfig::query()->where('tenant_id', tenant('id'))->first();

        if (! $config) {
            $this->bootstrapService->ensureDefaults(tenant('id'));
            $config = PointConfig::query()->where('tenant_id', tenant('id'))->first();
        }

        return ApiResponse::success($this->format($config));
    }

    public function update(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'loyalty.update');

        $validated = $request->validate([
            'earn_amount' => ['required', 'numeric', 'min:1'],
            'earn_points' => ['required', 'integer', 'min:1'],
            'redeem_points' => ['required', 'integer', 'min:1'],
            'redeem_value' => ['required', 'numeric', 'min:1'],
            'min_redeem_points' => ['required', 'integer', 'min:1'],
            'point_expiry_days' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $config = PointConfig::query()->firstOrCreate(
            ['tenant_id' => tenant('id')],
            [
                'earn_amount' => 10_000,
                'earn_points' => 1,
                'redeem_points' => 100,
                'redeem_value' => 10_000,
                'min_redeem_points' => 100,
                'is_active' => true,
            ],
        );

        $config->update($validated);

        return ApiResponse::success($this->format($config->fresh()));
    }

    protected function format(PointConfig $config): array
    {
        return [
            'earn_amount' => (float) $config->earn_amount,
            'earn_points' => $config->earn_points,
            'redeem_points' => $config->redeem_points,
            'redeem_value' => (float) $config->redeem_value,
            'min_redeem_points' => $config->min_redeem_points,
            'point_expiry_days' => $config->point_expiry_days,
            'is_active' => (bool) $config->is_active,
        ];
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses konfigurasi poin.');
        }
    }
}