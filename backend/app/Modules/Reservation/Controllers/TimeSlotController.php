<?php

namespace App\Modules\Reservation\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Reservation\Models\ReservationTimeSlot;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TimeSlotController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.view');

        $slots = ReservationTimeSlot::query()
            ->when($request->integer('outlet_id'), fn ($q, $id) => $q->where('outlet_id', $id))
            ->orderBy('day_of_week')
            ->orderBy('start_time')
            ->get()
            ->map(fn ($s) => $this->format($s));

        return ApiResponse::success($slots);
    }

    public function store(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.create');

        $validated = $request->validate([
            'outlet_id' => ['required', 'integer', 'exists:outlets,id'],
            'day_of_week' => ['required', 'integer', 'min:0', 'max:6'],
            'start_time' => ['required', 'date_format:H:i'],
            'end_time' => ['required', 'date_format:H:i', 'after:start_time'],
            'capacity' => ['required', 'integer', 'min:1'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $slot = ReservationTimeSlot::query()->create([
            'tenant_id' => tenant('id'),
            ...$validated,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return ApiResponse::success($this->format($slot), 'Slot waktu ditambahkan', 201);
    }

    public function update(Request $request, ReservationTimeSlot $timeSlot): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.update');

        $validated = $request->validate([
            'day_of_week' => ['sometimes', 'integer', 'min:0', 'max:6'],
            'start_time' => ['sometimes', 'date_format:H:i'],
            'end_time' => ['sometimes', 'date_format:H:i'],
            'capacity' => ['sometimes', 'integer', 'min:1'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $timeSlot->update($validated);

        return ApiResponse::success($this->format($timeSlot->fresh()));
    }

    public function destroy(Request $request, ReservationTimeSlot $timeSlot): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.delete');

        $timeSlot->delete();

        return ApiResponse::success(null, 'Slot waktu dihapus');
    }

    protected function format(ReservationTimeSlot $slot): array
    {
        return [
            'id' => $slot->id,
            'outlet_id' => $slot->outlet_id,
            'day_of_week' => $slot->day_of_week,
            'start_time' => substr((string) $slot->start_time, 0, 5),
            'end_time' => substr((string) $slot->end_time, 0, 5),
            'capacity' => $slot->capacity,
            'is_active' => $slot->is_active,
        ];
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses slot reservasi.');
        }
    }
}