<?php

use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Billing\Models\BillingPayment;
use App\Modules\Platform\Models\Subscription;

describe('Billing Webhook', function (): void {
    function midtransSignature(array $payload, string $serverKey): string
    {
        return hash(
            'sha512',
            ($payload['order_id'] ?? '')
            .($payload['status_code'] ?? '')
            .($payload['gross_amount'] ?? '')
            .$serverKey,
        );
    }

    it('marks invoice paid and activates subscription with valid Midtrans signature', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $invoice = $this->createInvoice($tenant, [
            'gateway_order_id' => 'CPOS-INV-VALID-001',
            'total_amount' => 150_000,
            'status' => 'sent',
        ]);

        $subscription = Subscription::query()->where('tenant_id', $tenant->id)->first();
        $subscription->update(['status' => 'past_due']);

        $payload = [
            'order_id' => 'CPOS-INV-VALID-001',
            'status_code' => '200',
            'gross_amount' => '150000.00',
            'transaction_status' => 'settlement',
            'fraud_status' => 'accept',
            'transaction_id' => 'MIDTRANS-TXN-001',
            'custom_field1' => (string) $invoice->id,
        ];

        $payload['signature_key'] = midtransSignature(
            $payload,
            config('creativepos.payment.midtrans.server_key'),
        );

        $response = $this->postJson('/api/v1/webhooks/payment/midtrans', $payload);

        $response->assertOk()->assertJsonPath('message', 'OK');

        $invoice->refresh();
        $subscription->refresh();

        expect($invoice->status)->toBe('paid')
            ->and($invoice->payment_status)->toBe('paid')
            ->and($invoice->paid_at)->not->toBeNull()
            ->and($subscription->status)->toBe('active');

        expect(BillingPayment::query()->where('invoice_id', $invoice->id)->count())->toBe(1);
    });

    it('rejects webhook with invalid signature and leaves invoice unchanged', function (): void {
        $tenant = $this->createTenant();
        $invoice = $this->createInvoice($tenant, [
            'gateway_order_id' => 'CPOS-INV-BAD-SIG',
            'status' => 'sent',
        ]);

        $payload = [
            'order_id' => 'CPOS-INV-BAD-SIG',
            'status_code' => '200',
            'gross_amount' => '111000.00',
            'transaction_status' => 'settlement',
            'fraud_status' => 'accept',
            'signature_key' => 'invalid-signature',
        ];

        $response = $this->postJson('/api/v1/webhooks/payment/midtrans', $payload);

        $response->assertForbidden();

        $invoice->refresh();
        expect($invoice->status)->toBe('sent')
            ->and($invoice->paid_at)->toBeNull();

        expect(BillingPayment::query()->where('invoice_id', $invoice->id)->count())->toBe(0);
    });

    it('is idempotent when the same paid webhook is sent twice', function (): void {
        $tenant = $this->createTenant();
        $invoice = $this->createInvoice($tenant, [
            'gateway_order_id' => 'CPOS-INV-IDEMP-001',
            'total_amount' => 99_000,
            'status' => 'sent',
        ]);

        $payload = [
            'order_id' => 'CPOS-INV-IDEMP-001',
            'status_code' => '200',
            'gross_amount' => '99000.00',
            'transaction_status' => 'capture',
            'fraud_status' => 'accept',
            'transaction_id' => 'MIDTRANS-TXN-IDEMP',
            'custom_field1' => (string) $invoice->id,
        ];

        $payload['signature_key'] = midtransSignature(
            $payload,
            config('creativepos.payment.midtrans.server_key'),
        );

        $this->postJson('/api/v1/webhooks/payment/midtrans', $payload)->assertOk();
        $this->postJson('/api/v1/webhooks/payment/midtrans', $payload)->assertOk();

        $invoice->refresh();

        expect($invoice->status)->toBe('paid')
            ->and(BillingPayment::query()->where('invoice_id', $invoice->id)->count())->toBe(1);
    });
});