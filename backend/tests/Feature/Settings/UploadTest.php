<?php

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

describe('Settings Upload & Outlet', function (): void {
    it('uploads a logo file for authenticated tenant user', function (): void {
        Storage::fake('public');

        $this->actingAsTenantUser(role: 'owner');

        $response = $this->post('/api/v1/uploads', [
            'file' => UploadedFile::fake()->image('logo.jpg', 200, 200),
            'type' => 'logo',
        ], [
            'Accept' => 'application/json',
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['url', 'path', 'type']]);
    });

    it('clamps onboarding current_step to maximum of 5', function (): void {
        $tenant = $this->createTenant();
        $this->actingAsTenantUser(role: 'owner', tenant: $tenant);

        $this->patchJson('/api/v1/settings/onboarding-progress', [
            'current_step' => 6,
            'skipped_steps' => ['staff'],
        ])->assertOk()
            ->assertJsonPath('data.current_step', 5);
    });

    it('resolves outlet by numeric id or uuid for updates', function (): void {
        $tenant = $this->createTenant();
        $user = $this->actingAsTenantUser(role: 'owner', tenant: $tenant);
        $outlet = $this->createOutlet($tenant);

        $this->putJson("/api/v1/settings/outlets/{$outlet->id}", [
            'name' => 'Outlet Updated By Id',
        ])->assertOk();

        $this->putJson("/api/v1/settings/outlets/{$outlet->uuid}", [
            'name' => 'Outlet Updated By Uuid',
        ])->assertOk()
            ->assertJsonPath('data.name', 'Outlet Updated By Uuid');
    });
});