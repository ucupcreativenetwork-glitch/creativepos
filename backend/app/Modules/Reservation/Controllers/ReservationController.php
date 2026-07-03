<?php

namespace App\Modules\Reservation\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Reservation\Models\Reservation;
use App\Modules\Reservation\Requests\StoreReservationRequest;
use App\Modules\Reservation\Requests\UpdateReservationRequest;
use App\Modules\Reservation\Requests\UpdateReservationStatusRequest;
use App\Modules\Reservation\Resources\ReservationResource;
use App\Modules\Reservation\Services\ReservationService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReservationController extends Controller
{
    public function __construct(
        private readonly ReservationService $reservationService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.view');

        $paginator = $this->reservationService->list(
            $request->integer('outlet_id') ?: null,
            $request->input('status'),
            $request->input('date'),
            $request->integer('per_page', 15),
        );

        return ApiResponse::success(
            ReservationResource::collection($paginator->items()),
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

    public function calendar(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.view');

        $calendar = $this->reservationService->calendar(
            $request->integer('outlet_id') ?: null,
            $request->input('from'),
            $request->input('to'),
        );

        return ApiResponse::success($calendar);
    }

    public function slots(Request $request): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.view');

        $request->validate([
            'outlet_id' => ['required', 'integer', 'exists:outlets,id'],
            'date' => ['required', 'date'],
        ]);

        $slots = $this->reservationService->availableSlots(
            $request->integer('outlet_id'),
            $request->input('date'),
        );

        return ApiResponse::success($slots);
    }

    public function show(Request $request, Reservation $reservation): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.view');

        $reservation = $this->reservationService->findByUuid($reservation->uuid);

        return ApiResponse::success(new ReservationResource($reservation));
    }

    public function store(StoreReservationRequest $request): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.create');

        $reservation = $this->reservationService->create($request->validated(), $request->user());

        return ApiResponse::created(new ReservationResource($reservation));
    }

    public function update(UpdateReservationRequest $request, Reservation $reservation): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.update');

        $reservation = $this->reservationService->update($reservation, $request->validated());

        return ApiResponse::success(new ReservationResource($reservation));
    }

    public function updateStatus(UpdateReservationStatusRequest $request, Reservation $reservation): JsonResponse
    {
        $this->authorizePermission($request, 'reservation.update');

        $reservation = $this->reservationService->updateStatus(
            $reservation,
            $request->input('status'),
            $request->user(),
            $request->input('notes'),
        );

        return ApiResponse::success(new ReservationResource($reservation));
    }

    protected function authorizePermission(Request $request, string $permission): void
    {
        $user = $request->user();

        if ($user && ! $user->is_super_admin && ! $user->can($permission)) {
            abort(403, 'Anda tidak memiliki izin untuk mengakses reservasi.');
        }
    }
}