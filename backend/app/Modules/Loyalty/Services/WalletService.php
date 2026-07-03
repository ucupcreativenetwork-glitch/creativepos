<?php

namespace App\Modules\Loyalty\Services;

use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Models\Wallet;
use App\Modules\Loyalty\Repositories\WalletRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class WalletService
{
    public function __construct(
        private readonly WalletRepository $repository,
    ) {}

    public function getWallet(Member $member): Wallet
    {
        return $this->repository->findOrCreate($member->id);
    }

    public function transactions(Member $member, int $perPage = 20): LengthAwarePaginator
    {
        $wallet = $this->getWallet($member);

        return $this->repository->history($wallet->id, $perPage);
    }

    public function topup(Member $member, float $amount, ?string $description = null): Wallet
    {
        if ($amount <= 0) {
            abort(422, 'Jumlah top-up harus lebih dari 0.');
        }

        return DB::transaction(function () use ($member, $amount, $description) {
            $wallet = $this->getWallet($member);
            $this->assertActive($wallet);

            $before = (float) $wallet->balance;
            $after = $before + $amount;

            $wallet = $this->repository->updateBalance($wallet, $after, $amount);
            $this->repository->recordTransaction([
                'tenant_id' => tenant('id'),
                'wallet_id' => $wallet->id,
                'type' => 'topup',
                'amount' => $amount,
                'balance_before' => $before,
                'balance_after' => $after,
                'description' => $description ?? 'Top-up saldo',
                'created_at' => now(),
            ]);

            return $wallet;
        });
    }

    public function withdraw(Member $member, float $amount, ?string $description = null): Wallet
    {
        if ($amount <= 0) {
            abort(422, 'Jumlah penarikan harus lebih dari 0.');
        }

        return DB::transaction(function () use ($member, $amount, $description) {
            $wallet = $this->getWallet($member);
            $this->assertActive($wallet);

            $before = (float) $wallet->balance;

            if ($amount > $before) {
                abort(422, 'Saldo wallet tidak mencukupi.');
            }

            $after = $before - $amount;

            $wallet = $this->repository->updateBalance($wallet, $after);
            $this->repository->recordTransaction([
                'tenant_id' => tenant('id'),
                'wallet_id' => $wallet->id,
                'type' => 'withdraw',
                'amount' => $amount,
                'balance_before' => $before,
                'balance_after' => $after,
                'description' => $description ?? 'Penarikan saldo',
                'created_at' => now(),
            ]);

            return $wallet;
        });
    }

    public function transfer(Member $from, Member $to, float $amount, ?string $description = null): array
    {
        if ($amount <= 0) {
            abort(422, 'Jumlah transfer harus lebih dari 0.');
        }

        if ($from->id === $to->id) {
            abort(422, 'Tidak dapat transfer ke diri sendiri.');
        }

        return DB::transaction(function () use ($from, $to, $amount, $description) {
            $fromWallet = $this->getWallet($from);
            $toWallet = $this->getWallet($to);

            $this->assertActive($fromWallet);
            $this->assertActive($toWallet);

            $fromBefore = (float) $fromWallet->balance;

            if ($amount > $fromBefore) {
                abort(422, 'Saldo wallet tidak mencukupi.');
            }

            $fromAfter = $fromBefore - $amount;
            $toBefore = (float) $toWallet->balance;
            $toAfter = $toBefore + $amount;

            $fromWallet = $this->repository->updateBalance($fromWallet, $fromAfter, 0, $amount);
            $toWallet = $this->repository->updateBalance($toWallet, $toAfter, $amount);

            $this->repository->recordTransaction([
                'tenant_id' => tenant('id'),
                'wallet_id' => $fromWallet->id,
                'type' => 'transfer_out',
                'amount' => $amount,
                'balance_before' => $fromBefore,
                'balance_after' => $fromAfter,
                'reference_type' => 'members',
                'reference_id' => $to->id,
                'description' => $description ?? "Transfer ke {$to->name}",
                'created_at' => now(),
            ]);

            $this->repository->recordTransaction([
                'tenant_id' => tenant('id'),
                'wallet_id' => $toWallet->id,
                'type' => 'transfer_in',
                'amount' => $amount,
                'balance_before' => $toBefore,
                'balance_after' => $toAfter,
                'reference_type' => 'members',
                'reference_id' => $from->id,
                'description' => $description ?? "Transfer dari {$from->name}",
                'created_at' => now(),
            ]);

            return [
                'from_wallet' => $fromWallet,
                'to_wallet' => $toWallet,
            ];
        });
    }

    protected function assertActive(Wallet $wallet): void
    {
        if ($wallet->status !== 'active') {
            abort(422, 'Wallet tidak aktif.');
        }
    }
}