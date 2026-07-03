<?php

namespace App\Modules\Delivery\Controllers;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Modules\Delivery\Models\DeliveryDriver;
use App\Modules\Delivery\Repositories\DeliveryDriverRepository;
use App\Modules\Delivery\Requests\StoreDeliveryDriverRequest;
use App\Modules\Delivery\Resources\DeliveryDriverResource;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class DeliveryDriverController extends Controller
{
    public function __construct(
        private readonly DeliveryDriverRepository $driverRepository,
    ) {}

    public function store(StoreDeliveryDriverRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.create');

        $user = User::query()
            ->where('tenant_id', tenant('id'))
            ->findOrFail($request->integer('user_id'));

        if (DeliveryDriver::query()->where('user_id', $user->id)->exists()) {
            abort(422, 'Pengguna ini sudah terdaftar sebagai driver.');
        }

        $driver = DeliveryDriver::query()->create([
            'tenant_id' => tenant('id'),
            'uuid' => (string) Str::uuid(),
            'user_id' => $user->id,
            'outlet_id' => $request->integer('outlet_id') ?: $user->outlet_id,
            'vehicle_type' => $request->input('vehicle_type', 'motor'),
            'vehicle_plate' => $request->input('vehicle_plate'),
            'is_active' => true,
            'is_available' => $request->boolean('is_available', true),
        ]);

        $driver->load(['user', 'outlet']);

        return ApiResponse::success(new DeliveryDriverResource($driver), 'Driver ditambahkan', 201);
    }

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.view');

        $drivers = $this->driverRepository->list(
            $request->integer('outlet_id') ?: null,
            $request->boolean('available_only') ?: null,
        );

        return ApiResponse::success(DeliveryDriverResource::collection($drivers));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses driver.');
        }
    }
}