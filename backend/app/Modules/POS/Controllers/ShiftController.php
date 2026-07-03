<?php

namespace App\Modules\POS\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\POS\Models\Shift;
use App\Modules\POS\Requests\CloseShiftRequest;
use App\Modules\POS\Requests\OpenShiftRequest;
use App\Modules\POS\Resources\ShiftResource;
use App\Modules\POS\Services\ShiftService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShiftController extends Controller
{
    public function __construct(
        private readonly ShiftService $shiftService,
    ) {}

    public function current(Request $request): JsonResponse
    {
        $this->authorizeShift($request);

        $shift = $this->shiftService->getCurrent(
            $request->user(),
            $request->integer('outlet_id') ?: null,
        );

        if (! $shift) {
            return ApiResponse::success(null, 'Tidak ada shift terbuka.');
        }

        return ApiResponse::success(new ShiftResource($shift));
    }

    public function open(OpenShiftRequest $request): JsonResponse
    {
        $this->authorizeShift($request);

        $shift = $this->shiftService->open(
            $request->user(),
            $request->integer('outlet_id'),
            (float) $request->input('opening_cash'),
        );

        return ApiResponse::created(new ShiftResource($shift->load(['outlet', 'cashier'])));
    }

    public function close(CloseShiftRequest $request, Shift $shift): JsonResponse
    {
        $this->authorizeShift($request);

        $shift = $this->shiftService->close(
            $request->user(),
            $shift,
            (float) $request->input('closing_cash'),
            $request->input('notes'),
        );

        return ApiResponse::success(new ShiftResource($shift->load(['outlet', 'cashier'])));
    }

    public function report(Request $request, Shift $shift): JsonResponse
    {
        $this->authorizeShift($request);

        $shift->load(['outlet', 'cashier']);

        return ApiResponse::success(new ShiftResource($shift));
    }

    protected function authorizeShift(Request $request): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can('pos.shift.open') && ! $user->can('pos.shift.close')) {
            abort(403, 'Anda tidak memiliki izin untuk mengelola shift.');
        }
    }
}