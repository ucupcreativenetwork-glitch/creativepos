<?php

namespace Database\Seeders;

use App\Modules\Loyalty\Models\Member;
use App\Modules\Loyalty\Models\MemberPoint;
use App\Modules\Loyalty\Models\Wallet;
use App\Modules\Loyalty\Services\LoyaltyBootstrapService;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class LoyaltySeeder extends Seeder
{
    public function run(): void
    {
        $tenants = Tenant::query()->get();

        foreach ($tenants as $tenant) {
            set_tenant($tenant);
            $this->seedForTenant($tenant);
        }
    }

    protected function seedForTenant(Tenant $tenant): void
    {
        app(LoyaltyBootstrapService::class)->ensureDefaults($tenant->id);

        $bronzeId = \App\Modules\Loyalty\Models\TierConfig::query()
            ->where('tenant_id', $tenant->id)
            ->where('slug', 'bronze')
            ->value('id');

        $members = Member::query()->where('tenant_id', $tenant->id)->get();

        foreach ($members as $index => $member) {
            if (! $member->qr_token) {
                $member->update([
                    'qr_token' => Str::random(32),
                    'tier_id' => $bronzeId,
                ]);
            }

            MemberPoint::query()->firstOrCreate(
                ['member_id' => $member->id],
                [
                    'tenant_id' => $tenant->id,
                    'balance' => ($index + 1) * 50,
                    'lifetime_earned' => ($index + 1) * 100,
                    'lifetime_redeemed' => ($index + 1) * 50,
                ]
            );

            Wallet::query()->firstOrCreate(
                ['member_id' => $member->id],
                [
                    'tenant_id' => $tenant->id,
                    'balance' => ($index + 1) * 25000,
                    'lifetime_topup' => ($index + 1) * 50000,
                    'lifetime_spent' => ($index + 1) * 25000,
                    'status' => 'active',
                ]
            );
        }
    }
}