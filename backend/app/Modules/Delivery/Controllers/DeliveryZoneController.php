<?php

namespace App\Modules\Delivery\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Delivery\Models\DeliveryZone;
use App\Modules\Delivery\Models\DeliveryZoneRate;
use App\Modules\Delivery\Repositories\DeliveryZoneRepository;
use App\Modules\Delivery\Requests\CalculateFeeRequest;
use App\Modules\Delivery\Requests\StoreDeliveryZoneRequest;
use App\Modules\Delivery\Resources\DeliveryZoneResource;
use App\Modules\Delivery\Services\DeliveryFeeService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class DeliveryZoneController extends Controller
{
    public function __construct(
        private readonly DeliveryZoneRepository $zoneRepository,
        private readonly DeliveryFeeService $feeService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.view');

        $zones = $this->zoneRepository->list($request->integer('outlet_id') ?: null);

        return ApiResponse::success(DeliveryZoneResource::collection($zones));
    }

    public function store(StoreDeliveryZoneRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.create');

        $zone = DB::transaction(function () use ($request) {
            $zone = DeliveryZone::query()->create([
                'tenant_id' => tenant('id'),
                'uuid' => (string) Str::uuid(),
                'outlet_id' => $request->integer('outlet_id'),
                'name' => $request->string('name'),
                'code' => strtoupper($request->string('code')),
                'description' => $request->input('description'),
                'is_active' => true,
            ]);

            DeliveryZoneRate::query()->create([
                'tenant_id' => tenant('id'),
                'delivery_zone_id' => $zone->id,
                'min_distance_km' => 0,
                'max_distance_km' => $request->input('max_distance_km', 50),
                'base_fee' => $request->input('base_fee'),
                'fee_per_km' => $request->input('fee_per_km', 0),
                'is_active' => true,
            ]);

            return $zone->load(['rates', 'outlet']);
        });

        return ApiResponse::success(new DeliveryZoneResource($zone), 'Zona delivery dibuat', 201);
    }

    public function calculateFee(CalculateFeeRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'delivery.create');

        $result = $this->feeService->calculate(
            $request->integer('zone_id'),
            (float) $request->input('distance_km'),
        );

        return ApiResponse::success($result);
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses zona delivery.');
        }
    }
}