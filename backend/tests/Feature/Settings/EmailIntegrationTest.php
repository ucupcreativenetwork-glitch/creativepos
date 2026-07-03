<?php

use App\Modules\Settings\Models\EmailConfig;
use Illuminate\Support\Facades\Mail;

describe('Settings Email Integration', function (): void {
    it('sends a test email in log mode when email gateway is not configured', function (): void {
        Mail::fake();
        config(['mail.default' => 'log']);

        $this->actingAsTenantUser(role: 'owner');

        $response = $this->postJson('/api/v1/settings/integrations/email/test', [
            'email' => 'owner@creativepos.test',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.mode', 'log')
            ->assertJsonPath('data.success', true);
    });

    it('sends a test email via tenant SMTP when configuration is active', function (): void {
        Mail::fake();

        $tenant = $this->createTenant();
        $this->actingAsTenantUser(role: 'owner', tenant: $tenant);

        EmailConfig::query()->create([
            'tenant_id' => $tenant->id,
            'mailer' => 'smtp',
            'host' => 'smtp.example.com',
            'port' => 587,
            'encryption' => 'tls',
            'username' => 'smtp-user',
            'password' => 'smtp-secret',
            'from_address' => 'noreply@example.com',
            'from_name' => 'CreativePOS Test',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/v1/settings/integrations/email/test', [
            'email' => 'recipient@example.com',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.mode', 'smtp')
            ->assertJsonPath('data.success', true);
    });

    it('tests email using inline SMTP settings from the request', function (): void {
        Mail::fake();

        $this->actingAsTenantUser(role: 'owner');

        $response = $this->postJson('/api/v1/settings/integrations/email/test', [
            'email' => 'inline@example.com',
            'mailer' => 'smtp',
            'host' => 'smtp.mailtrap.io',
            'port' => 587,
            'encryption' => 'tls',
            'username' => 'inline-user',
            'password' => 'inline-pass',
            'from_address' => 'noreply@test.com',
            'is_active' => true,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.mode', 'smtp');
    });

    it('returns validation error for invalid recipient email', function (): void {
        $this->actingAsTenantUser(role: 'owner');

        $response = $this->postJson('/api/v1/settings/integrations/email/test', [
            'email' => 'not-an-email',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    });

    it('updates email integration configuration', function (): void {
        $tenant = $this->createTenant();
        $this->actingAsTenantUser(role: 'owner', tenant: $tenant);

        $response = $this->putJson('/api/v1/settings/integrations/email', [
            'config' => [
                'mailer' => 'smtp',
                'host' => 'smtp.gmail.com',
                'port' => 587,
                'encryption' => 'tls',
                'username' => 'bisnis@gmail.com',
                'password' => 'app-password',
                'from_address' => 'bisnis@gmail.com',
                'from_name' => 'Toko Saya',
                'send_welcome_email' => true,
            ],
            'is_active' => true,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.provider', 'email')
            ->assertJsonPath('data.is_active', true)
            ->assertJsonPath('data.config.host', 'smtp.gmail.com');

        $this->assertDatabaseHas('email_configs', [
            'tenant_id' => $tenant->id,
            'host' => 'smtp.gmail.com',
            'is_active' => true,
        ]);
    });
});