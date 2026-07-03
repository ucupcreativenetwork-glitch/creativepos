<?php

namespace App\Modules\Loyalty\Repositories;

use App\Modules\Loyalty\Models\Wallet;
use App\Modules\Loyalty\Models\WalletTransaction;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class WalletRepository
{
    public function findOrCreate(int $memberId): Wallet
    {
        return Wallet::query()->firstOrCreate(
            ['member_id' => $memberId],
            [
                'tenant_id' => tenant('id'),
                'balance' => 0,
                'lifetime_topup' => 0,
                'lifetime_spent' => 0,
                'status' => 'active',
            ]
        );
    }

    public function findByMemberId(int $memberId): ?Wallet
    {
        return Wallet::query()
            ->where('member_id', $memberId)
            ->first();
    }

    public function updateBalance(Wallet $wallet, float $balance, float $topupDelta = 0, float $spentDelta = 0): Wallet
    {
        $wallet->update([
            'balance' => $balance,
            'lifetime_topup' => $wallet->lifetime_topup + $topupDelta,
            'lifetime_spent' => $wallet->lifetime_spent + $spentDelta,
        ]);

        return $wallet->fresh();
    }

    public function recordTransaction(array $data): WalletTransaction
    {
        return WalletTransaction::query()->create($data);
    }

    public function history(int $walletId, int $perPage = 20): LengthAwarePaginator
    {
        return WalletTransaction::query()
            ->where('wallet_id', $walletId)
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }
}