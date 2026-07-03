<?php

namespace App\Modules\POS\Repositories;

use App\Modules\POS\Models\SaleTransaction;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class TransactionRepository
{
    public function paginate(
        ?int $outletId = null,
        ?string $status = null,
        ?string $search = null,
        int $perPage = 15,
    ): LengthAwarePaginator {
        $query = SaleTransaction::query()
            ->with([
                'outlet:id,name,code',
                'cashier:id,name',
                'items',
                'payments.paymentMethod:id,name,code,type',
            ])
            ->orderByDesc('created_at');

        if ($outletId) {
            $query->where('outlet_id', $outletId);
        }

        if ($status) {
            $query->where('status', $status);
        }

        if ($search) {
            $query->where('transaction_number', 'like', "%{$search}%");
        }

        return $query->paginate($perPage);
    }

    public function findByUuid(string $uuid): ?SaleTransaction
    {
        return SaleTransaction::query()
            ->with([
                'outlet:id,name,code,address',
                'cashier:id,name',
                'items.product:id,name,sku',
                'payments.paymentMethod:id,name,code,type',
                'shift:id,shift_number',
            ])
            ->where('uuid', $uuid)
            ->first();
    }

    public function create(array $data): SaleTransaction
    {
        return SaleTransaction::query()->create($data);
    }

    public function update(SaleTransaction $transaction, array $data): SaleTransaction
    {
        $transaction->update($data);

        return $transaction->fresh();
    }

    public function countTodayTransactions(): int
    {
        return SaleTransaction::query()
            ->whereDate('created_at', today())
            ->count();
    }
}