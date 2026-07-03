<?php

namespace App\Modules\Dashboard\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Dashboard\Services\DashboardService;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __construct(
        private readonly DashboardService $dashboard,
    ) {}

    public function kpi(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'dashboard.view');

        $data = $this->dashboard->getKpi(
            $request->integer('outlet_id') ?: null
        );

        return ApiResponse::success($data);
    }

    public function salesChart(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'dashboard.view');

        $data = $this->dashboard->getSalesChart(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
            $request->input('period', 'daily'),
        );

        return ApiResponse::success($data);
    }

    public function productPerformance(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'dashboard.view');

        $data = $this->dashboard->getProductPerformance(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
            $request->integer('limit', 10),
        );

        return ApiResponse::success($data);
    }

    public function customerGrowth(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'dashboard.view');

        $data = $this->dashboard->getCustomerGrowth(
            $request->integer('outlet_id') ?: null,
            $request->input('date_from'),
            $request->input('date_to'),
        );

        return ApiResponse::success($data);
    }

    public function outletPerformance(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'dashboard.view');

        $data = $this->dashboard->getOutletPerformance(
            $request->input('date_from'),
            $request->input('date_to'),
        );

        return ApiResponse::success($data);
    }

    public function liveFeed(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'dashboard.view');

        $data = $this->dashboard->getLiveFeed(
            $request->integer('outlet_id') ?: null,
            $request->integer('limit', 10),
        );

        return ApiResponse::success($data);
    }

    public function outlets(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'dashboard.view');

        $outlets = Outlet::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get(['id', 'uuid', 'name', 'code', 'is_default']);

        return ApiResponse::success($outlets);
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'You do not have permission to access the dashboard.');
        }
    }
}