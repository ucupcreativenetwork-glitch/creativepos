<?php

use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Billing\Services\Gateways\MidtransGateway;

describe('Billing Invoice', function (): void {
    it('creates an invoice and checkout returns snap token', function (): void {
        $tenant = $this->createTenant();
        $owner = $this->actingAsTenantUser(null, $tenant, 'owner');

        $invoice = $this->createInvoice($tenant, [
            'status' => 'sent',
            'total_amount' => 111_000,
        ]);

        $this->mock(MidtransGateway::class, function ($mock) use ($invoice): void {
            $mock->shouldReceive('createCharge')->once()->andReturn([
                'gateway_order_id' => 'CPOS-'.$invoice->invoice_number.'-MOCK01',
                'payment_url' => 'https://app.sandbox.midtrans.com/snap/v4/redirection/mock',
                'payment_instructions' => [
                    'provider' => 'midtrans',
                    'method' => 'gopay',
                    'snap_token' => 'mock-snap-token-abc123',
                ],
                'payment_expires_at' => now()->addHours(24)->toIso8601String(),
                'gateway_metadata' => ['snap_token' => 'mock-snap-token-abc123'],
            ]);
        });

        config(['creativepos.payment.midtrans.server_key' => 'SB-Mid-server-test']);

        $response = $this->postJson("/api/v1/billing/invoices/{$invoice->id}/pay", [
            'payment_method' => 'gopay',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.payment_instructions.snap_token', 'mock-snap-token-abc123')
            ->assertJsonPath('data.gateway_order_id', 'CPOS-'.$invoice->invoice_number.'-MOCK01');

        $invoice->refresh();
        expect($invoice->payment_status)->toBe('pending')
            ->and($invoice->payment_method)->toBe('gopay');
    });

    it('cannot checkout an invoice that is already paid', function (): void {
        $tenant = $this->createTenant();
        $this->actingAsTenantUser(null, $tenant, 'owner');

        $invoice = $this->createInvoice($tenant, [
            'status' => 'paid',
            'total_amount' => 111_000,
        ]);

        $response = $this->postJson("/api/v1/billing/invoices/{$invoice->id}/pay", [
            'payment_method' => 'gopay',
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Invoice tidak dapat dibayar.');

        expect(BillingInvoice::query()->find($invoice->id)->status)->toBe('paid');
    });
});