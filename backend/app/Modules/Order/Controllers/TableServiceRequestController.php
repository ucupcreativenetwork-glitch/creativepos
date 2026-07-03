<?php

namespace App\Modules\Order\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Order\Models\TableServiceRequest;
use App\Modules\Order\Services\TableServiceRequestService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TableServiceRequestController extends Controller
{
    public function __construct(
        private readonly TableServiceRequestService $service,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'order.view');

        $paginator = $this->service->list(
            $request->integer('outlet_id') ?: null,
            $request->input('status'),
            $request->integer('per_page', 20),
        );

        return ApiResponse::success(
            $paginator->items()->map(fn (TableServiceRequest $r) => $this->toArray($r)),
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

    public function acknowledge(Request $request, string $uuid): JsonResponse
    {
        $this->authorizePermission($request, 'order.view');

        $record = TableServiceRequest::query()->where('uuid', $uuid)->firstOrFail();
        $updated = $this->service->acknowledge($record, $request->user());

        return ApiResponse::success($this->toArray($updated), 'Permintaan ditandai selesai.');
    }

    /**
     * @return array<string, mixed>
     */
    protected function toArray(TableServiceRequest $request): array
    {
        return [
            'id' => $request->id,
            'uuid' => $request->uuid,
            'type' => $request->type,
            'status' => $request->status,
            'outlet_id' => $request->outlet_id,
            'outlet_name' => $request->outlet?->name,
            'table_id' => $request->table_id,
            'table_number' => $request->table_number,
            'table_area' => $request->table_area,
            'table_token' => $request->table_token,
            'acknowledged_at' => $request->acknowledged_at?->toIso8601String(),
            'created_at' => $request->created_at?->toIso8601String(),
        ];
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses permintaan meja.');
        }
    }
}