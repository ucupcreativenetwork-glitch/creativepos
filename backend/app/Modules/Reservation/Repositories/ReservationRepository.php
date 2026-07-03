<?php

namespace App\Modules\Reservation\Repositories;

use App\Modules\Reservation\Models\Reservation;
use App\Modules\Reservation\Models\ReservationTimeSlot;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;

class ReservationRepository
{
    public function paginate(
        ?int $outletId = null,
        ?string $status = null,
        ?string $date = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        $query = Reservation::query()
            ->with(['outlet:id,name,code', 'table:id,table_number,name', 'member:id,name,member_code'])
            ->orderByDesc('reservation_date')
            ->orderBy('reservation_time');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        if ($status) {
            $query->where('status', $status);
        }

        if ($date) {
            $query->whereDate('reservation_date', $date);
        }

        return $query->paginate($perPage);
    }

    public function calendar(?int $outletId = null, ?string $from = null, ?string $to = null): Collection
    {
        $query = Reservation::query()
            ->with(['outlet:id,name,code', 'table:id,table_number,name'])
            ->whereNotIn('status', ['cancelled', 'no_show'])
            ->orderBy('reservation_time');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        if ($from) {
            $query->whereDate('reservation_date', '>=', $from);
        }

        if ($to) {
            $query->whereDate('reservation_date', '<=', $to);
        }

        return $query->get();
    }

    public function findByUuid(string $uuid): ?Reservation
    {
        return Reservation::query()
            ->with(['outlet', 'table', 'member', 'statusHistories.changer:id,name'])
            ->where('uuid', $uuid)
            ->first();
    }

    public function create(array $data): Reservation
    {
        return Reservation::query()->create($data);
    }

    public function update(Reservation $reservation, array $data): Reservation
    {
        $reservation->update($data);

        return $reservation->fresh();
    }

    public function countToday(): int
    {
        return Reservation::query()->whereDate('created_at', today())->count();
    }

    public function countForSlot(int $outletId, string $date, string $startTime, string $endTime): int
    {
        return Reservation::query()
            ->where('outlet_id', $outletId)
            ->whereDate('reservation_date', $date)
            ->where('reservation_time', '>=', $startTime)
            ->where('reservation_time', '<', $endTime)
            ->whereNotIn('status', ['cancelled', 'no_show'])
            ->count();
    }

    public function activeSlotsForDay(int $outletId, int $dayOfWeek): Collection
    {
        return ReservationTimeSlot::query()
            ->where('outlet_id', $outletId)
            ->where('day_of_week', $dayOfWeek)
            ->where('is_active', true)
            ->orderBy('start_time')
            ->get();
    }

    public function findSlotForTime(int $outletId, int $dayOfWeek, string $time): ?ReservationTimeSlot
    {
        return ReservationTimeSlot::query()
            ->where('outlet_id', $outletId)
            ->where('day_of_week', $dayOfWeek)
            ->where('is_active', true)
            ->where('start_time', '<=', $time)
            ->where('end_time', '>', $time)
            ->first();
    }

    public function parseDayOfWeek(string $date): int
    {
        return Carbon::parse($date)->dayOfWeek;
    }
}