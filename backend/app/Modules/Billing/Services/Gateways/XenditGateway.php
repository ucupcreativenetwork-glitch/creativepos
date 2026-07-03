<?php

namespace App\Modules\Billing\Services\Gateways;

use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Platform\Models\Subscription;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class XenditGateway
{
    public function isConfigured(): bool
    {
        return filled(config('creativepos.payment.xendit.secret_key'));
    }

    /**
     * @return array{
     *     gateway_order_id: string,
     *     payment_url: ?string,
     *     payment_instructions: array<string, mixed>,
     *     payment_expires_at: ?string,
     *     gateway_metadata: array<string, mixed>
     * }
     */
    public function createInvoiceCharge(BillingInvoice $invoice, Tenant $tenant, bool $recurring = false): array
    {
        if (! $this->isConfigured()) {
            return $this->mockCharge($invoice, $recurring);
        }

        $externalId = $this->buildExternalId($invoice);
        $payload = [
            'external_id' => $externalId,
            'amount' => (float) $invoice->total_amount,
            'payer_email' => $tenant->email ?? 'billing@'.$tenant->slug.'.creativepos.app',
            'description' => 'CreativePOS Subscription - '.$invoice->invoice_number,
            'invoice_duration' => 86400,
            'payment_methods' => ['CREDIT_CARD'],
            'success_redirect_url' => config('creativepos.payment.frontend_url').'/settings?tab=subscription&payment=success',
            'failure_redirect_url' => config('creativepos.payment.frontend_url').'/settings?tab=subscription&payment=failed',
            'metadata' => [
                'invoice_id' => $invoice->id,
                'tenant_id' => $invoice->tenant_id,
                'recurring' => $recurring,
            ],
        ];

        $response = Http::withBasicAuth(config('creativepos.payment.xendit.secret_key'), '')
            ->acceptJson()
            ->post('https://api.xendit.co/v2/invoices', $payload);

        if (! $response->successful()) {
            throw new \RuntimeException(
                'Xendit invoice failed: '.($response->json('message') ?? $response->body())
            );
        }

        $data = $response->json();

        return [
            'gateway_order_id' => $externalId,
            'payment_url' => $data['invoice_url'] ?? null,
            'payment_instructions' => [
                'provider' => 'xendit',
                'method' => 'credit_card',
                'recurring' => $recurring,
                'invoice_id' => $data['id'] ?? null,
                'status' => $data['status'] ?? 'PENDING',
            ],
            'payment_expires_at' => isset($data['expiry_date'])
                ? \Carbon\Carbon::parse($data['expiry_date'])->toIso8601String()
                : now()->addDay()->toIso8601String(),
            'gateway_metadata' => $data,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function setupRecurring(Subscription $subscription, Tenant $tenant): array
    {
        if (! $this->isConfigured()) {
            return [
                'customer_id' => 'mock-cust-'.Str::lower(Str::random(8)),
                'recurring_id' => 'mock-rec-'.Str::lower(Str::random(8)),
                'payment_url' => config('creativepos.payment.frontend_url').'/settings?tab=subscription&recurring=mock',
                'mode' => 'sandbox_mock',
            ];
        }

        $customer = $this->ensureCustomer($subscription, $tenant);

        $amount = $subscription->billing_cycle === 'yearly'
            ? (float) $subscription->package->price_yearly
            : (float) $subscription->package->price_monthly;

        $interval = $subscription->billing_cycle === 'yearly' ? 'YEAR' : 'MONTH';
        $intervalCount = 1;

        $response = Http::withBasicAuth(config('creativepos.payment.xendit.secret_key'), '')
            ->acceptJson()
            ->post('https://api.xendit.co/recurring_payments', [
                'external_id' => 'CPOS-REC-'.$subscription->id.'-'.Str::upper(Str::random(4)),
                'payer_email' => $tenant->email ?? 'billing@'.$tenant->slug.'.creativepos.app',
                'description' => 'CreativePOS '.$subscription->package->name.' Subscription',
                'amount' => $amount,
                'interval' => $interval,
                'interval_count' => $intervalCount,
                'customer_id' => $customer['id'],
                'currency' => 'IDR',
                'success_redirect_url' => config('creativepos.payment.frontend_url').'/settings?tab=subscription&recurring=success',
                'failure_redirect_url' => config('creativepos.payment.frontend_url').'/settings?tab=subscription&recurring=failed',
            ]);

        if (! $response->successful()) {
            throw new \RuntimeException(
                'Xendit recurring setup failed: '.($response->json('message') ?? $response->body())
            );
        }

        $data = $response->json();

        return [
            'customer_id' => $customer['id'],
            'recurring_id' => $data['id'] ?? null,
            'payment_url' => $data['actions']['auth_url'] ?? $data['actions']['redirect_url'] ?? null,
            'metadata' => $data,
        ];
    }

    public function verifyWebhookToken(?string $token): bool
    {
        $expected = config('creativepos.payment.xendit.webhook_token');

        if (! filled($expected)) {
            return false;
        }

        return filled($token) && hash_equals($expected, $token);
    }

    public function parseInvoiceStatus(array $payload): string
    {
        $status = strtoupper($payload['status'] ?? '');

        return match ($status) {
            'PAID', 'SETTLED' => 'paid',
            'EXPIRED' => 'expired',
            'PENDING' => 'processing',
            default => 'failed',
        };
    }

    /**
     * @return array<string, mixed>
     */
    protected function ensureCustomer(Subscription $subscription, Tenant $tenant): array
    {
        if (filled($subscription->xendit_customer_id)) {
            return ['id' => $subscription->xendit_customer_id];
        }

        $response = Http::withBasicAuth(config('creativepos.payment.xendit.secret_key'), '')
            ->acceptJson()
            ->post('https://api.xendit.co/customers', [
                'reference_id' => 'tenant-'.$tenant->id,
                'email' => $tenant->email ?? 'billing@'.$tenant->slug.'.creativepos.app',
                'given_names' => $tenant->name,
                'mobile_number' => $tenant->phone,
            ]);

        if (! $response->successful()) {
            throw new \RuntimeException(
                'Xendit customer creation failed: '.($response->json('message') ?? $response->body())
            );
        }

        return $response->json();
    }

    protected function buildExternalId(BillingInvoice $invoice): string
    {
        return 'CPOS-XND-'.$invoice->invoice_number.'-'.Str::upper(Str::random(6));
    }

    /**
     * @return array{
     *     gateway_order_id: string,
     *     payment_url: ?string,
     *     payment_instructions: array<string, mixed>,
     *     payment_expires_at: ?string,
     *     gateway_metadata: array<string, mixed>
     * }
     */
    protected function mockCharge(BillingInvoice $invoice, bool $recurring): array
    {
        $externalId = $this->buildExternalId($invoice);
        $expiresAt = now()->addDay()->toIso8601String();

        return [
            'gateway_order_id' => $externalId,
            'payment_url' => config('creativepos.payment.frontend_url').'/settings?tab=subscription&payment=mock',
            'payment_instructions' => [
                'provider' => 'xendit',
                'method' => 'credit_card',
                'recurring' => $recurring,
                'mode' => 'sandbox_mock',
                'status' => 'PENDING',
            ],
            'payment_expires_at' => $expiresAt,
            'gateway_metadata' => ['mock' => true],
        ];
    }
}