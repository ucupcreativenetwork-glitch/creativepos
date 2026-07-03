<?php

namespace App\Modules\Delivery\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Delivery\Models\DeliveryOrder;
use App\Modules\Delivery\Requests\AssignDriverRequest;
use App\Modules\Delivery\Requests\RecordLocationRequest;
use App\Modules\Delivery\Requests\StoreDeliveryOrderRequest;
use App\Modules\Delivery\Requests\UpdateDeliveryStatusRequest;
use App\Modules\Delivery\Resources\DeliveryOrderResource;
use App\Modules\Delivery\Services\DeliveryService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeliveryOrderController extends Controller
{
    public function __construct(
        private readonly DeliveryService $deliveryService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.view');

        $paginator = $this->deliveryService->list(
            $request->integer('outlet_id') ?: null,
            $request->input('status'),
            $request->integer('driver_id') ?: null,
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            DeliveryOrderResource::collection($paginator->items()),
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

    public function show(Request $request, DeliveryOrder $deliveryOrder): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.view');

        $order = $this->deliveryService->findByUuid($deliveryOrder->uuid);

        return ApiResponse::success(new DeliveryOrderResource($order));
    }

    public function store(StoreDeliveryOrderRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.create');

        $order = $this->deliveryService->create($request->validated(), $request->user());

        return ApiResponse::created(new DeliveryOrderResource($order));
    }

    public function updateStatus(UpdateDeliveryStatusRequest $request, DeliveryOrder $deliveryOrder): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.update');

        $order = $this->deliveryService->updateStatus(
            $deliveryOrder,
            $request->input('status'),
            $request->user(),
            $request->input('notes'),
        );

        return ApiResponse::success(new DeliveryOrderResource($order));
    }

    public function assign(AssignDriverRequest $request, DeliveryOrder $deliveryOrder): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.assign');

        $order = $this->deliveryService->assignDriver(
            $deliveryOrder,
            $request->integer('driver_id'),
        );

        return ApiResponse::success(new DeliveryOrderResource($order));
    }

    public function location(RecordLocationRequest $request, DeliveryOrder $deliveryOrder): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.update');

        $order = $this->deliveryService->recordLocation(
            $deliveryOrder,
            (float) $request->input('latitude'),
            (float) $request->input('longitude'),
            $request->integer('driver_id') ?: null,
        );

        return ApiResponse::success(new DeliveryOrderResource($order));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses delivery.');
        }
    }
}