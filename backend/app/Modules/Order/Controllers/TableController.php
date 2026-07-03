<?php

namespace App\Modules\Order\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Order\Models\Table;
use App\Modules\Order\Models\TableQrCode;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class TableController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'order.view');

        $tables = Table::query()
            ->with(['outlet:id,name,code', 'qrCode'])
            ->when($request->integer('outlet_id'), fn ($q, $id) => $q->where('outlet_id', $id))
            ->orderBy('table_number')
            ->get()
            ->map(fn ($t) => $this->format($t));

        return ApiResponse::success($tables);
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'order.create');

        $validated = $request->validate([
            'outlet_id' => ['required', 'integer', 'exists:outlets,id'],
            'table_number' => ['required', 'string', 'max:20'],
            'name' => ['nullable', 'string', 'max:100'],
            'capacity' => ['required', 'integer', 'min:1'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $table = Table::query()->create([
            'tenant_id' => tenant('id'),
            ...$validated,
            'status' => 'available',
            'is_active' => $validated['is_active'] ?? true,
        ]);

        $table->load(['outlet:id,name,code', 'qrCode']);

        return ApiResponse::success($this->format($table), 'Meja ditambahkan', 201);
    }

    public function update(Request $request, Table $table): JsonResponse
    {
        $this->authorizePermission($request, 'order.update');

        $validated = $request->validate([
            'table_number' => ['sometimes', 'string', 'max:20'],
            'name' => ['nullable', 'string', 'max:100'],
            'capacity' => ['sometimes', 'integer', 'min:1'],
            'status' => ['sometimes', 'in:available,occupied,reserved,cleaning'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $table->update($validated);
        $table->load(['outlet:id,name,code', 'qrCode']);

        return ApiResponse::success($this->format($table));
    }

    public function generateQr(Request $request, Table $table): JsonResponse
    {
        $this->authorizePermission($request, 'order.update');

        $qr = TableQrCode::query()->updateOrCreate(
            ['table_id' => $table->id, 'tenant_id' => tenant('id')],
            [
                'qr_token' => Str::random(32),
                'is_active' => true,
                'created_at' => now(),
            ],
        );

        $tenant = tenant();
        $outlet = $table->outlet;
        $menuUrl = \App\Shared\Support\FrontendUrl::path(
            "menu/{$tenant->slug}/{$outlet?->code}/table/{$qr->qr_token}"
        );

        return ApiResponse::success([
            'qr_token' => $qr->qr_token,
            'menu_url' => $menuUrl,
            'table_id' => $table->id,
        ]);
    }

    protected function format(Table $table): array
    {
        return [
            'id' => $table->id,
            'outlet_id' => $table->outlet_id,
            'outlet' => $table->outlet ? [
                'id' => $table->outlet->id,
                'name' => $table->outlet->name,
                'code' => $table->outlet->code,
            ] : null,
            'table_number' => $table->table_number,
            'name' => $table->name,
            'capacity' => $table->capacity,
            'status' => $table->status,
            'is_active' => $table->is_active,
            'qr_token' => $table->qrCode?->qr_token,
        ];
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses meja.');
        }
    }
}