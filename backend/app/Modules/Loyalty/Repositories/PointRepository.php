<?php

namespace App\Modules\Loyalty\Repositories;

use App\Modules\Loyalty\Models\MemberPoint;
use App\Modules\Loyalty\Models\PointConfig;
use App\Modules\Loyalty\Models\PointTransaction;
use App\Modules\Loyalty\Services\LoyaltyBootstrapService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class PointRepository
{
    public function __construct(
        private readonly LoyaltyBootstrapService $loyaltyBootstrap,
    ) {}

    public function getConfig(): ?PointConfig
    {
        $this->loyaltyBootstrap->ensureDefaults();

        return PointConfig::query()->where('is_active', true)->first();
    }

    public function findOrCreateMemberPoints(int $memberId): MemberPoint
    {
        return MemberPoint::query()->firstOrCreate(
            ['member_id' => $memberId],
            [
                'tenant_id' => tenant('id'),
                'balance' => 0,
                'lifetime_earned' => 0,
                'lifetime_redeemed' => 0,
            ]
        );
    }

    public function recordTransaction(array $data): PointTransaction
    {
        return PointTransaction::query()->create($data);
    }

    public function history(int $memberId, int $perPage = 20): LengthAwarePaginator
    {
        return PointTransaction::query()
            ->where('member_id', $memberId)
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function updateBalance(MemberPoint $points, int $balance, int $earnedDelta = 0, int $redeemedDelta = 0): MemberPoint
    {
        $points->update([
            'balance' => $balance,
            'lifetime_earned' => $points->lifetime_earned + $earnedDelta,
            'lifetime_redeemed' => $points->lifetime_redeemed + $redeemedDelta,
        ]);

        return $points->fresh();
    }
}