<?php

namespace App\Modules\Loyalty\Services;

use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Repositories\PointRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class PointService
{
    public function __construct(
        private readonly PointRepository $repository,
    ) {}

    public function getBalance(Member $member): array
    {
        $points = $this->repository->findOrCreateMemberPoints($member->id);
        $config = $this->repository->getConfig();

        return [
            'balance' => $points->balance,
            'lifetime_earned' => $points->lifetime_earned,
            'lifetime_redeemed' => $points->lifetime_redeemed,
            'config' => $config ? [
                'earn_amount' => (float) $config->earn_amount,
                'earn_points' => $config->earn_points,
                'redeem_points' => $config->redeem_points,
                'redeem_value' => (float) $config->redeem_value,
                'min_redeem_points' => $config->min_redeem_points,
            ] : null,
        ];
    }

    public function history(Member $member, int $perPage = 20): LengthAwarePaginator
    {
        return $this->repository->history($member->id, $perPage);
    }

    public function earn(
        Member $member,
        int $points,
        ?string $referenceType = null,
        ?int $referenceId = null,
        ?string $description = null,
    ): void {
        if ($points <= 0) {
            return;
        }

        DB::transaction(function () use ($member, $points, $referenceType, $referenceId, $description) {
            $record = $this->repository->findOrCreateMemberPoints($member->id);
            $newBalance = $record->balance + $points;

            $this->repository->updateBalance($record, $newBalance, $points);
            $this->repository->recordTransaction([
                'tenant_id' => tenant('id'),
                'member_id' => $member->id,
                'type' => 'earn',
                'points' => $points,
                'balance_after' => $newBalance,
                'reference_type' => $referenceType,
                'reference_id' => $referenceId,
                'description' => $description,
                'created_at' => now(),
            ]);
        });
    }

    public function earnFromPurchase(Member $member, float $amount, int $transactionId): void
    {
        $config = $this->repository->getConfig();

        if (! $config || $config->earn_amount <= 0) {
            return;
        }

        $multiplier = (float) ($member->tier?->point_multiplier ?? 1);
        $basePoints = (int) floor($amount / $config->earn_amount) * $config->earn_points;
        $points = (int) floor($basePoints * $multiplier);

        if ($points > 0) {
            $this->earn(
                $member,
                $points,
                'sale_transactions',
                $transactionId,
                'Poin dari transaksi POS',
            );
        }
    }

    public function previewRedeem(Member $member, int $points): array
    {
        $config = $this->repository->getConfig();

        if (! $config) {
            abort(422, 'Konfigurasi poin belum diatur.');
        }

        if ($points < $config->min_redeem_points) {
            abort(422, "Minimal redeem {$config->min_redeem_points} poin.");
        }

        $record = $this->repository->findOrCreateMemberPoints($member->id);

        if ($record->balance < $points) {
            abort(422, "Saldo poin tidak mencukupi. Saldo saat ini: {$record->balance} poin.");
        }

        $discountValue = ($points / $config->redeem_points) * $config->redeem_value;

        return [
            'points' => $points,
            'discount_value' => round((float) $discountValue, 2),
            'config' => [
                'redeem_points' => $config->redeem_points,
                'redeem_value' => (float) $config->redeem_value,
                'min_redeem_points' => $config->min_redeem_points,
            ],
        ];
    }

    public function redeem(Member $member, int $points, ?string $description = null): array
    {
        $config = $this->repository->getConfig();

        if (! $config) {
            abort(422, 'Konfigurasi poin belum diatur.');
        }

        if ($points < $config->min_redeem_points) {
            abort(422, "Minimal redeem {$config->min_redeem_points} poin.");
        }

        return DB::transaction(function () use ($member, $points, $config, $description) {
            $record = $this->repository->findOrCreateMemberPoints($member->id);

            if ($record->balance < $points) {
                abort(422, "Saldo poin tidak mencukupi. Saldo saat ini: {$record->balance} poin.");
            }

            $newBalance = $record->balance - $points;
            $this->repository->updateBalance($record, $newBalance, 0, $points);

            $this->repository->recordTransaction([
                'tenant_id' => tenant('id'),
                'member_id' => $member->id,
                'type' => 'redeem',
                'points' => -$points,
                'balance_after' => $newBalance,
                'description' => $description ?? 'Redeem poin',
                'created_at' => now(),
            ]);

            $discountValue = ($points / $config->redeem_points) * $config->redeem_value;

            return [
                'points_redeemed' => $points,
                'balance_after' => $newBalance,
                'discount_value' => round((float) $discountValue, 2),
            ];
        });
    }

    public function adjust(Member $member, int $points, string $description): void
    {
        DB::transaction(function () use ($member, $points, $description) {
            $record = $this->repository->findOrCreateMemberPoints($member->id);
            $newBalance = max(0, $record->balance + $points);

            $earnedDelta = $points > 0 ? $points : 0;
            $redeemedDelta = $points < 0 ? abs($points) : 0;

            $this->repository->updateBalance($record, $newBalance, $earnedDelta, $redeemedDelta);
            $this->repository->recordTransaction([
                'tenant_id' => tenant('id'),
                'member_id' => $member->id,
                'type' => 'adjustment',
                'points' => $points,
                'balance_after' => $newBalance,
                'description' => $description,
                'created_at' => now(),
            ]);
        });
    }
}