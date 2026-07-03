<?php

namespace App\Modules\POS\Repositories;

use App\Modules\POS\Models\SalePayment;
use App\Modules\POS\Models\Shift;

class ShiftRepository
{
    public function findOpenForCashier(int $cashierId, ?int $outletId = null): ?Shift
    {
        $query = Shift::query()
            ->with(['outlet:id,name,code', 'cashier:id,name'])
            ->where('cashier_id', $cashierId)
            ->where('status', 'open');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        return $query->latest('opened_at')->first();
    }

    public function create(array $data): Shift
    {
        return Shift::query()->create($data);
    }

    public function update(Shift $shift, array $data): Shift
    {
        $shift->update($data);

        return $shift->fresh();
    }

    public function countTodayShifts(): int
    {
        return Shift::query()
            ->whereDate('opened_at', today())
            ->count();
    }

    public function cashSalesForShift(int $shiftId): float
    {
        return (float) SalePayment::query()
            ->whereHas('transaction', fn ($q) => $q->where('shift_id', $shiftId)->where('status', 'completed'))
            ->whereHas('paymentMethod', fn ($q) => $q->where('type', 'cash'))
            ->where('status', 'completed')
            ->sum('amount');
    }
}