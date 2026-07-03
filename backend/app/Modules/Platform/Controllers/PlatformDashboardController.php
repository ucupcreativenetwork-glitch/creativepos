<?php

namespace App\Modules\Platform\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Platform\Services\PlatformDashboardService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlatformDashboardController extends Controller
{
    public function __construct(
        private readonly PlatformDashboardService $dashboardService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePlatform($request);

        return ApiResponse::success($this->dashboardService->getDashboard());
    }

    protected function authorizePlatform(Request $request): void
    {
        if (! $request->user()?->is_super_admin) {
            abort(403, 'Super admin access required.');
        }
    }
}