<?php

use App\Models\User;
use Laravel\Sanctum\Sanctum;

describe('Auth Login', function (): void {
    it('logs in successfully with valid credentials', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant, [
            'email' => 'owner@creativepos.test',
            'password' => 'secret-password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'owner@creativepos.test',
            'password' => 'secret-password',
            'device_name' => 'Pest Test',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'owner@creativepos.test')
            ->assertJsonStructure(['data' => ['token']]);

        expect($response->json('data.token'))->not->toBeEmpty();
        expect($user->fresh()->last_login_at)->not->toBeNull();
    });

    it('fails login with wrong password', function (): void {
        $tenant = $this->createTenant();
        $this->createUser('owner', $tenant, [
            'email' => 'wrong-pass@creativepos.test',
            'password' => 'correct-password',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'wrong-pass@creativepos.test',
            'password' => 'incorrect-password',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'The provided credentials are incorrect.');
    });

    it('fails login for inactive accounts', function (): void {
        $tenant = $this->createTenant();
        $this->createUser('owner', $tenant, [
            'email' => 'inactive@creativepos.test',
            'password' => 'password123',
            'status' => 'inactive',
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'inactive@creativepos.test',
            'password' => 'password123',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'Your account is not active.');
    });
});