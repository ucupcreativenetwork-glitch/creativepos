<?php

use Illuminate\Support\Facades\Cache;

describe('Auth Rate Limit', function (): void {
    it('rate limits login after more than five failed attempts', function (): void {
        Cache::flush();

        $tenant = $this->createTenant();
        $this->createUser('owner', $tenant, [
            'email' => 'ratelimit@creativepos.test',
            'password' => 'correct-password',
        ]);

        for ($attempt = 1; $attempt <= 5; $attempt++) {
            $response = $this->postJson('/api/v1/auth/login', [
                'email' => 'ratelimit@creativepos.test',
                'password' => 'wrong-password',
            ]);

            $response->assertStatus(422)
                ->assertJsonPath('errors.email.0', 'The provided credentials are incorrect.');
        }

        $blocked = $this->postJson('/api/v1/auth/login', [
            'email' => 'ratelimit@creativepos.test',
            'password' => 'wrong-password',
        ]);

        $blocked->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'Too many login attempts. Please try again later.');
    });
});