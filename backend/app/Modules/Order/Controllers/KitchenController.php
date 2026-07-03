<?php

namespace App\Modules\Order\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Order\Models\Order;
use App\Modules\Order\Repositories\OrderRepository;
use App\Modules\Order\Resources\OrderResource;
use App\Modules\Order\Services\OrderService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class KitchenController extends Controller
{
    public function __construct(
        private readonly OrderRepository $repository,
        private readonly OrderService $orderService,
    ) {}

    public function queue(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'kitchen.view');

        $orders = $this->repository->kitchenQueue(
            $request->integer('outlet_id') ?: null,
        );

        return ApiResponse::success(OrderResource::collection($orders));
    }

    public function bump(Request $request, Order $order): JsonResponse
    {
        $this->authorizePermission($request, 'order.update');

        $order = $this->orderService->bump($order, $request->user());

        return ApiResponse::success(new OrderResource($order), 'Status pesanan diperbarui.');
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses dapur.');
        }
    }
}