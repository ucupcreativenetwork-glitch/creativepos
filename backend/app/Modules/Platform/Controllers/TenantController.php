<?php

namespace App\Modules\Platform\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Platform\Services\PlatformTenantService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TenantController extends Controller
{
    public function __construct(
        private readonly PlatformTenantService $tenantService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePlatform($request);

        $paginator = $this->tenantService->listTenants(
            $request->input('search'),
            $request->input('status'),
            $request->integer('per_page', 15),
        );

        $paginator->through(fn (Tenant $tenant) => [
            'id' => $tenant->id,
            'uuid' => $tenant->uuid,
            'name' => $tenant->name,
            'slug' => $tenant->slug,
            'email' => $tenant->email,
            'phone' => $tenant->phone,
            'status' => $tenant->status,
            'trial_ends_at' => $tenant->trial_ends_at?->toIso8601String(),
            'suspended_at' => $tenant->suspended_at?->toIso8601String(),
            'subscription' => $tenant->activeSubscription ? [
                'id' => $tenant->activeSubscription->id,
                'status' => $tenant->activeSubscription->status,
                'billing_cycle' => $tenant->activeSubscription->billing_cycle,
                'ends_at' => $tenant->activeSubscription->ends_at?->toDateString(),
                'package' => $tenant->activeSubscription->package?->only(['id', 'name', 'slug']),
            ] : null,
            'created_at' => $tenant->created_at?->toIso8601String(),
        ]);

        return ApiResponse::success(
            $paginator->items(),
            'Operation successful',
            200,
            [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        );
    }

    public function suspend(Request $request, Tenant $tenant): JsonResponse
    {
        $this->authorizePlatform($request);

        $tenant = $this->tenantService->suspend($tenant);

        return ApiResponse::success([
            'id' => $tenant->id,
            'status' => $tenant->status,
            'suspended_at' => $tenant->suspended_at?->toIso8601String(),
        ], 'Tenant suspended successfully.');
    }

    public function activate(Request $request, Tenant $tenant): JsonResponse
    {
        $this->authorizePlatform($request);

        $tenant = $this->tenantService->activate($tenant);

        return ApiResponse::success([
            'id' => $tenant->id,
            'status' => $tenant->status,
            'suspended_at' => $tenant->suspended_at,
        ], 'Tenant activated successfully.');
    }

    protected function authorizePlatform(Request $request): void
    {
        if (! $request->user()?->is_super_admin) {
            abort(403, 'Super admin access required.');
        }
    }
}