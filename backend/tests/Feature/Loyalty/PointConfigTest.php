<?php

use App\Modules\Loyalty\Models\MemberPoint;
use App\Modules\Loyalty\Models\PointConfig;

describe('Loyalty Point Config', function (): void {
    it('adjusts member points manually', function (): void {
        $tenant = $this->createTenant();
        $this->actingAsTenantUser(role: 'owner', tenant: $tenant);
        $member = $this->createMember($tenant, ['points_balance' => 0]);

        $this->postJson("/api/v1/members/{$member->uuid}/points/adjust", [
            'points' => 150,
            'description' => 'Bonus member baru',
        ])->assertOk()
            ->assertJsonPath('data.balance', 150);

        $this->postJson("/api/v1/members/{$member->uuid}/points/redeem", [
            'points' => 100,
        ])->assertOk();
    });

    it('auto-provisions default point config when redeeming without prior setup', function (): void {
        $tenant = $this->createTenant();
        $user = $this->actingAsTenantUser(role: 'owner', tenant: $tenant);
        $member = $this->createMember($tenant, ['points_balance' => 500]);

        PointConfig::query()->where('tenant_id', $tenant->id)->delete();

        expect(PointConfig::query()->where('tenant_id', $tenant->id)->exists())->toBeFalse();

        $this->postJson("/api/v1/members/{$member->uuid}/points/redeem", [
            'points' => 100,
        ])->assertOk()
            ->assertJsonPath('data.points_redeemed', 100);

        expect(PointConfig::query()->where('tenant_id', $tenant->id)->where('is_active', true)->exists())
            ->toBeTrue();
    });
});