<?php

describe('Member Show', function (): void {
    it('returns member detail by uuid', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant);
        $member = $this->createMember($tenant, ['name' => 'Member Uji']);

        $this->actingAsTenantUser($user, $tenant);

        $this->getJson("/api/v1/members/{$member->uuid}")
            ->assertOk()
            ->assertJsonPath('data.name', 'Member Uji');
    });

    it('returns member detail by numeric id', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant);
        $member = $this->createMember($tenant, ['name' => 'Member By ID']);

        $this->actingAsTenantUser($user, $tenant);

        $this->getJson("/api/v1/members/{$member->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $member->id);
    });
});