<?php

namespace App\Modules\Reservation\Services;

use App\Models\User;
use App\Modules\Reservation\Models\Reservation;
use App\Modules\Reservation\Models\ReservationStatusHistory;
use App\Modules\Reservation\Repositories\ReservationRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class ReservationService
{
    public function __construct(
        private readonly ReservationRepository $repository,
    ) {}

    public function list(
        ?int $outletId = null,
        ?string $status = null,
        ?string $date = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        return $this->repository->paginate($outletId, $status, $date, $perPage);
    }

    public function findByUuid(string $uuid): Reservation
    {
        $reservation = $this->repository->findByUuid($uuid);

        if (! $reservation) {
            abort(404, 'Reservasi tidak ditemukan.');
        }

        return $reservation;
    }

    public function calendar(?int $outletId = null, ?string $from = null, ?string $to = null): array
    {
        $from = $from ?? today()->toDateString();
        $to = $to ?? today()->addDays(30)->toDateString();

        $reservations = $this->repository->calendar($outletId, $from, $to);

        return $reservations
            ->groupBy(fn ($r) => $r->reservation_date->toDateString())
            ->map(fn ($items, $date) => [
                'date' => $date,
                'count' => $items->count(),
                'guests' => $items->sum('guest_count'),
                'reservations' => $items->map(fn ($r) => [
                    'uuid' => $r->uuid,
                    'reservation_number' => $r->reservation_number,
                    'customer_name' => $r->customer_name,
                    'reservation_time' => substr((string) $r->reservation_time, 0, 5),
                    'guest_count' => $r->guest_count,
                    'status' => $r->status,
                    'table' => $r->table ? [
                        'id' => $r->table->id,
                        'table_number' => $r->table->table_number,
                        'name' => $r->table->name,
                    ] : null,
                ])->values(),
            ])
            ->values()
            ->all();
    }

    public function availableSlots(int $outletId, string $date): array
    {
        $dayOfWeek = $this->repository->parseDayOfWeek($date);
        $slots = $this->repository->activeSlotsForDay($outletId, $dayOfWeek);

        return $slots->map(function ($slot) use ($outletId, $date) {
            $startTime = $this->normalizeTime(substr((string) $slot->start_time, 0, 5));
            $endTime = $this->normalizeTime(substr((string) $slot->end_time, 0, 5));
            $booked = $this->repository->countForSlot($outletId, $date, $startTime, $endTime);
            $available = max(0, $slot->capacity - $booked);

            return [
                'id' => $slot->id,
                'start_time' => substr((string) $slot->start_time, 0, 5),
                'end_time' => substr((string) $slot->end_time, 0, 5),
                'capacity' => $slot->capacity,
                'booked' => $booked,
                'available' => $available,
                'is_available' => $available > 0,
            ];
        })->values()->all();
    }

    public function create(array $data, ?User $user = null): Reservation
    {
        return DB::transaction(function () use ($data, $user) {
            $this->validateSlotCapacity(
                $data['outlet_id'],
                $data['reservation_date'],
                $data['reservation_time'],
            );

            $count = $this->repository->countToday();
            $reservation = $this->repository->create([
                'tenant_id' => tenant('id'),
                'reservation_number' => 'RSV-'.now()->format('Ymd').'-'.str_pad((string) ($count + 1), 4, '0', STR_PAD_LEFT),
                'outlet_id' => $data['outlet_id'],
                'member_id' => $data['member_id'] ?? null,
                'table_id' => $data['table_id'] ?? null,
                'customer_name' => $data['customer_name'],
                'customer_phone' => $data['customer_phone'],
                'customer_email' => $data['customer_email'] ?? null,
                'guest_count' => $data['guest_count'],
                'reservation_date' => $data['reservation_date'],
                'reservation_time' => $this->normalizeTime($data['reservation_time']),
                'status' => 'pending',
                'notes' => $data['notes'] ?? null,
            ]);

            $this->recordStatus($reservation, null, 'pending', $user?->id, 'Reservasi dibuat');

            if ($reservation->table_id) {
                \App\Modules\Order\Models\Table::query()
                    ->where('id', $reservation->table_id)
                    ->update(['status' => 'reserved']);
            }

            return $this->repository->findByUuid($reservation->uuid);
        });
    }

    public function update(Reservation $reservation, array $data): Reservation
    {
        return DB::transaction(function () use ($reservation, $data) {
            $date = $data['reservation_date'] ?? $reservation->reservation_date->toDateString();
            $time = isset($data['reservation_time'])
                ? $this->normalizeTime($data['reservation_time'])
                : $reservation->reservation_time;

            if (
                ($data['reservation_date'] ?? null) !== null
                || ($data['reservation_time'] ?? null) !== null
            ) {
                $this->validateSlotCapacity(
                    $data['outlet_id'] ?? $reservation->outlet_id,
                    $date,
                    $time,
                    $reservation->id,
                );
            }

            if (isset($data['reservation_time'])) {
                $data['reservation_time'] = $this->normalizeTime($data['reservation_time']);
            }

            $oldTableId = $reservation->table_id;
            $this->repository->update($reservation, $data);

            if (isset($data['table_id']) && $data['table_id'] !== $oldTableId) {
                if ($oldTableId) {
                    \App\Modules\Order\Models\Table::query()
                        ->where('id', $oldTableId)
                        ->update(['status' => 'available']);
                }

                if ($data['table_id']) {
                    \App\Modules\Order\Models\Table::query()
                        ->where('id', $data['table_id'])
                        ->update(['status' => 'reserved']);
                }
            }

            return $this->repository->findByUuid($reservation->uuid);
        });
    }

    public function updateStatus(
        Reservation $reservation,
        string $status,
        ?User $user = null,
        ?string $notes = null,
    ): Reservation {
        $allowed = ['pending', 'confirmed', 'arrived', 'completed', 'cancelled', 'no_show'];

        if (! in_array($status, $allowed, true)) {
            abort(422, 'Status tidak valid.');
        }

        return DB::transaction(function () use ($reservation, $status, $user, $notes) {
            $from = $reservation->status;
            $extra = ['status' => $status];

            if ($status === 'confirmed' && ! $reservation->confirmed_at) {
                $extra['confirmed_at'] = now();
            }

            if ($status === 'arrived' && ! $reservation->arrived_at) {
                $extra['arrived_at'] = now();
            }

            if ($status === 'cancelled' && ! $reservation->cancelled_at) {
                $extra['cancelled_at'] = now();
            }

            $this->repository->update($reservation, $extra);
            $this->recordStatus($reservation, $from, $status, $user?->id, $notes);

            if (in_array($status, ['cancelled', 'no_show', 'completed'], true) && $reservation->table_id) {
                \App\Modules\Order\Models\Table::query()
                    ->where('id', $reservation->table_id)
                    ->update(['status' => 'available']);
            }

            return $this->repository->findByUuid($reservation->uuid);
        });
    }

    protected function validateSlotCapacity(
        int $outletId,
        string $date,
        string $time,
        ?int $excludeReservationId = null,
    ): void {
        $time = $this->normalizeTime($time);
        $dayOfWeek = $this->repository->parseDayOfWeek($date);
        $slot = $this->repository->findSlotForTime($outletId, $dayOfWeek, $time);

        if (! $slot) {
            abort(422, 'Slot waktu tidak tersedia untuk outlet ini.');
        }

        $booked = $this->repository->countForSlot(
            $outletId,
            $date,
            (string) $slot->start_time,
            (string) $slot->end_time,
        );

        if ($excludeReservationId) {
            $current = Reservation::query()->find($excludeReservationId);

            if (
                $current
                && $current->reservation_date->toDateString() === $date
                && $current->reservation_time >= $slot->start_time
                && $current->reservation_time < $slot->end_time
                && ! in_array($current->status, ['cancelled', 'no_show'], true)
            ) {
                $booked = max(0, $booked - 1);
            }
        }

        if ($booked >= $slot->capacity) {
            abort(422, 'Kapasitas slot waktu sudah penuh.');
        }
    }

    protected function normalizeTime(string $time): string
    {
        if (strlen($time) === 5) {
            return $time.':00';
        }

        return $time;
    }

    protected function recordStatus(
        Reservation $reservation,
        ?string $from,
        string $to,
        ?int $userId,
        ?string $notes,
    ): void {
        ReservationStatusHistory::query()->create([
            'reservation_id' => $reservation->id,
            'from_status' => $from,
            'to_status' => $to,
            'changed_by' => $userId,
            'notes' => $notes,
            'created_at' => now(),
        ]);
    }
}