<?php

namespace App\Modules\Inventory\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Inventory\Models\RawMaterial;
use App\Modules\Inventory\Requests\RawMaterialStockRequest;
use App\Modules\Inventory\Requests\StoreRawMaterialRequest;
use App\Modules\Inventory\Requests\UpdateRawMaterialRequest;
use App\Modules\Inventory\Resources\RawMaterialResource;
use App\Modules\Inventory\Services\RawMaterialService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RawMaterialController extends Controller
{
    public function __construct(
        private readonly RawMaterialService $rawMaterialService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $paginator = $this->rawMaterialService->list(
            $request->input('search'),
            $request->has('is_active') ? $request->boolean('is_active') : null,
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            RawMaterialResource::collection($paginator->items()),
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

    public function alerts(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        $alerts = $this->rawMaterialService->lowStockAlerts($request->integer('limit', 20));

        return ApiResponse::success(RawMaterialResource::collection($alerts));
    }

    public function show(Request $request, RawMaterial $rawMaterial): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.view');

        return ApiResponse::success(new RawMaterialResource($rawMaterial));
    }

    public function store(StoreRawMaterialRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.create');

        $material = $this->rawMaterialService->create($request->validated());

        return ApiResponse::created(new RawMaterialResource($material));
    }

    public function update(UpdateRawMaterialRequest $request, RawMaterial $rawMaterial): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.update');

        $material = $this->rawMaterialService->update($rawMaterial, $request->validated());

        return ApiResponse::success(new RawMaterialResource($material));
    }

    public function destroy(Request $request, RawMaterial $rawMaterial): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.delete');

        $this->rawMaterialService->delete($rawMaterial);

        return ApiResponse::success(null, 'Bahan baku berhasil dihapus.');
    }

    public function stockIn(RawMaterialStockRequest $request, RawMaterial $rawMaterial): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.stock.adjust');

        $material = $this->rawMaterialService->stockIn(
            $rawMaterial,
            (float) $request->input('quantity'),
            $request->input('notes'),
        );

        return ApiResponse::success(new RawMaterialResource($material), 'Stok bahan baku berhasil ditambahkan.');
    }

    public function stockOut(RawMaterialStockRequest $request, RawMaterial $rawMaterial): JsonResponse
    {
        $this->authorizePermission($request, 'inventory.stock.adjust');

        $material = $this->rawMaterialService->stockOut(
            $rawMaterial,
            (float) $request->input('quantity'),
            $request->input('notes'),
        );

        return ApiResponse::success(new RawMaterialResource($material), 'Stok bahan baku berhasil dikurangi.');
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses inventori.');
        }
    }
}