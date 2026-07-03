<?php

use App\Modules\Settings\Models\WhatsappConfig;
use Illuminate\Support\Facades\Http;

describe('Settings WhatsApp Integration', function (): void {
    it('sends a test message in dev mode when WhatsApp is not configured', function (): void {
        $this->actingAsTenantUser(role: 'owner');

        $response = $this->postJson('/api/v1/settings/integrations/whatsapp/test', [
            'phone' => '081234567890',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.mode', 'dev')
            ->assertJsonPath('data.success', true);
    });

    it('sends a test message via Fonnte when configuration is active', function (): void {
        Http::fake([
            'api.fonnte.com/*' => Http::response([
                'status' => true,
                'detail' => 'Message sent',
            ]),
        ]);

        $tenant = $this->createTenant();
        $this->actingAsTenantUser(role: 'owner', tenant: $tenant);

        WhatsappConfig::query()->create([
            'tenant_id' => $tenant->id,
            'provider' => 'fonnte',
            'phone_number' => '6281234567890',
            'api_token' => 'test-fonnte-token',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/settings/integrations/whatsapp/test', [
            'phone' => '081234567890',
            'message' => 'Halo dari CreativePOS',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.mode', 'live')
            ->assertJsonPath('data.success', true);

        Http::assertSent(function ($request) {
            return str_contains($request->url(), 'api.fonnte.com')
                && $request['target'] === '081234567890'
                && $request['message'] === 'Halo dari CreativePOS';
        });
    });

    it('tests WhatsApp using inline token from the request', function (): void {
        Http::fake([
            'api.fonnte.com/*' => Http::response([
                'status' => true,
                'detail' => 'success! message in queue',
            ]),
        ]);

        $this->actingAsTenantUser(role: 'owner');

        $response = $this->postJson('/api/v1/settings/integrations/whatsapp/test', [
            'phone' => '081299988877',
            'gateway' => 'fonnte',
            'api_token' => 'inline-fonnte-token',
            'is_active' => true,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.mode', 'live');

        Http::assertSent(function ($request) {
            return $request->header('Authorization')[0] === 'inline-fonnte-token';
        });
    });

    it('returns validation error for invalid phone number', function (): void {
        $this->actingAsTenantUser(role: 'owner');

        $response = $this->postJson('/api/v1/settings/integrations/whatsapp/test', [
            'phone' => '12345',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['phone']);
    });
});