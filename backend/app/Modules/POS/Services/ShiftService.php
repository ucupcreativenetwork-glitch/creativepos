<?php

namespace App\Modules\POS\Services;

use App\Models\User;
use App\Modules\POS\Models\Shift;
use App\Modules\POS\Repositories\ShiftRepository;
use Illuminate\Support\Facades\DB;

class ShiftService
{
    public function __construct(
        private readonly ShiftRepository $repository,
    ) {}

    public function getCurrent(User $user, ?int $outletId = null): ?Shift
    {
        return $this->repository->findOpenForCashier($user->id, $outletId);
    }

    public function open(User $user, int $outletId, float $openingCash): Shift
    {
        $existing = $this->repository->findOpenForCashier($user->id, $outletId);

        if ($existing) {
            abort(422, 'Anda masih memiliki shift yang terbuka.');
        }

        $count = $this->repository->countTodayShifts();

        return $this->repository->create([
            'tenant_id' => tenant('id'),
            'outlet_id' => $outletId,
            'cashier_id' => $user->id,
            'shift_number' => 'SHF-'.now()->format('Ymd').'-'.str_pad((string) ($count + 1), 4, '0', STR_PAD_LEFT),
            'status' => 'open',
            'opening_cash' => $openingCash,
            'opened_at' => now(),
        ]);
    }

    public function close(User $user, Shift $shift, float $closingCash, ?string $notes = null): Shift
    {
        if ($shift->status !== 'open') {
            abort(422, 'Shift sudah ditutup.');
        }

        if ($shift->cashier_id !== $user->id && ! $user->is_super_admin) {
            abort(403, 'Anda tidak dapat menutup shift ini.');
        }

        $cashSales = $this->repository->cashSalesForShift($shift->id);
        $expectedCash = (float) $shift->opening_cash + $cashSales;

        return $this->repository->update($shift, [
            'status' => 'closed',
            'closing_cash' => $closingCash,
            'expected_cash' => $expectedCash,
            'cash_difference' => $closingCash - $expectedCash,
            'closed_at' => now(),
            'closed_by' => $user->id,
            'notes' => $notes,
        ]);
    }

    public function incrementTotals(Shift $shift, float $amount): void
    {
        $shift->increment('total_transactions');
        $shift->increment('total_sales', $amount);
    }
}