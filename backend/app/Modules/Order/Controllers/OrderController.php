<?php

namespace App\Modules\Order\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Order\Models\Order;
use App\Modules\Order\Requests\CreateOrderRequest;
use App\Modules\Order\Requests\UpdateOrderStatusRequest;
use App\Modules\Order\Resources\OrderResource;
use App\Modules\Order\Services\OrderService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    public function __construct(
        private readonly OrderService $orderService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'order.view');

        $paginator = $this->orderService->list(
            $request->integer('outlet_id') ?: null,
            $request->input('status'),
            $request->input('source'),
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            OrderResource::collection($paginator->items()),
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

    public function show(Request $request, Order $order): JsonResponse
    {
        $this->authorizePermission($request, 'order.view');

        $order = $this->orderService->findByUuid($order->uuid);

        return ApiResponse::success(new OrderResource($order));
    }

    public function store(CreateOrderRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'order.create');

        $order = $this->orderService->create($request->validated(), $request->user());

        return ApiResponse::created(new OrderResource($order));
    }

    public function updateStatus(UpdateOrderStatusRequest $request, Order $order): JsonResponse
    {
        $this->authorizePermission($request, 'order.update');

        $order = $this->orderService->updateStatus(
            $order,
            $request->input('status'),
            $request->user(),
            $request->input('notes'),
        );

        return ApiResponse::success(new OrderResource($order));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses pesanan.');
        }
    }
}