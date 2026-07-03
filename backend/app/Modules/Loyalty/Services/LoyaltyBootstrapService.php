<?php

namespace App\Modules\Loyalty\Services;

use App\Modules\Loyalty\Models\PointConfig;
use App\Modules\Loyalty\Models\TierConfig;

class LoyaltyBootstrapService
{
    public function ensureDefaults(?int $tenantId = null): void
    {
        $tenantId ??= tenant('id');

        if (! $tenantId) {
            return;
        }

        $this->ensureTiers($tenantId);
        $this->ensurePointConfig($tenantId);
    }

    protected function ensureTiers(int $tenantId): void
    {
        if (TierConfig::query()->where('tenant_id', $tenantId)->exists()) {
            return;
        }

        $tiers = [
            ['name' => 'Bronze', 'slug' => 'bronze', 'min_spend' => 0, 'point_multiplier' => 1.0, 'sort_order' => 1],
            ['name' => 'Silver', 'slug' => 'silver', 'min_spend' => 500000, 'point_multiplier' => 1.2, 'sort_order' => 2],
            ['name' => 'Gold', 'slug' => 'gold', 'min_spend' => 2000000, 'point_multiplier' => 1.5, 'sort_order' => 3],
            ['name' => 'Platinum', 'slug' => 'platinum', 'min_spend' => 5000000, 'point_multiplier' => 2.0, 'sort_order' => 4],
        ];

        foreach ($tiers as $tier) {
            TierConfig::query()->create([
                'tenant_id' => $tenantId,
                ...$tier,
                'is_active' => true,
            ]);
        }
    }

    protected function ensurePointConfig(int $tenantId): void
    {
        PointConfig::query()->firstOrCreate(
            ['tenant_id' => $tenantId],
            [
                'earn_amount' => 10000,
                'earn_points' => 1,
                'redeem_points' => 100,
                'redeem_value' => 10000,
                'min_redeem_points' => 100,
                'is_active' => true,
            ],
        );
    }
}