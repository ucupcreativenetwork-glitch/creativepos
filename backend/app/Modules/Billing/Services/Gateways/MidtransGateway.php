<?php

namespace App\Modules\Billing\Services\Gateways;

use App\Modules\Billing\Enums\BillingPaymentMethod;
use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class MidtransGateway
{
    public function isConfigured(): bool
    {
        return filled(config('creativepos.payment.midtrans.server_key'));
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
    public function createCharge(BillingInvoice $invoice, BillingPaymentMethod $method, Tenant $tenant): array
    {
        if (! $this->isConfigured()) {
            return $this->mockCharge($invoice, $method);
        }

        $orderId = $this->buildOrderId($invoice);
        $payload = $this->buildChargePayload($invoice, $method, $tenant, $orderId);

        $response = Http::withBasicAuth(config('creativepos.payment.midtrans.server_key'), '')
            ->acceptJson()
            ->post($this->baseUrl().'/v2/charge', $payload);

        if (! $response->successful()) {
            throw new \RuntimeException(
                'Midtrans charge failed: '.($response->json('status_message') ?? $response->body())
            );
        }

        $data = $response->json();
        $instructions = $this->extractInstructions($method, $data);

        return [
            'gateway_order_id' => $orderId,
            'payment_url' => $instructions['redirect_url'] ?? $instructions['deeplink'] ?? null,
            'payment_instructions' => $instructions,
            'payment_expires_at' => $instructions['expires_at'] ?? now()->addHours(24)->toIso8601String(),
            'gateway_metadata' => $data,
        ];
    }

    public function verifySignature(array $payload, string $signatureKey): bool
    {
        $orderId = $payload['order_id'] ?? '';
        $statusCode = $payload['status_code'] ?? '';
        $grossAmount = $payload['gross_amount'] ?? '';
        $serverKey = config('creativepos.payment.midtrans.server_key');

        if (! filled($serverKey)) {
            return false;
        }

        $expected = hash('sha512', $orderId.$statusCode.$grossAmount.$serverKey);

        return hash_equals($expected, $signatureKey);
    }

    public function parseNotificationStatus(array $payload): string
    {
        $transactionStatus = $payload['transaction_status'] ?? '';
        $fraudStatus = $payload['fraud_status'] ?? 'accept';

        if (in_array($transactionStatus, ['capture', 'settlement'], true) && $fraudStatus === 'accept') {
            return 'paid';
        }

        if (in_array($transactionStatus, ['pending'], true)) {
            return 'processing';
        }

        if (in_array($transactionStatus, ['expire'], true)) {
            return 'expired';
        }

        if (in_array($transactionStatus, ['cancel', 'deny', 'failure'], true)) {
            return 'failed';
        }

        return 'processing';
    }

    protected function buildOrderId(BillingInvoice $invoice): string
    {
        return 'CPOS-'.$invoice->invoice_number.'-'.Str::upper(Str::random(6));
    }

    /**
     * @return array<string, mixed>
     */
    protected function buildChargePayload(
        BillingInvoice $invoice,
        BillingPaymentMethod $method,
        Tenant $tenant,
        string $orderId,
    ): array {
        $base = [
            'transaction_details' => [
                'order_id' => $orderId,
                'gross_amount' => (int) round((float) $invoice->total_amount),
            ],
            'customer_details' => [
                'first_name' => $tenant->name,
                'email' => $tenant->email ?? 'billing@'.$tenant->slug.'.creativepos.app',
                'phone' => $tenant->phone ?? '',
            ],
            'custom_field1' => (string) $invoice->id,
            'custom_field2' => (string) $invoice->tenant_id,
        ];

        return match ($method) {
            BillingPaymentMethod::VaBca => array_merge($base, [
                'payment_type' => 'bank_transfer',
                'bank_transfer' => ['bank' => 'bca'],
            ]),
            BillingPaymentMethod::VaBni => array_merge($base, [
                'payment_type' => 'bank_transfer',
                'bank_transfer' => ['bank' => 'bni'],
            ]),
            BillingPaymentMethod::VaBri => array_merge($base, [
                'payment_type' => 'bank_transfer',
                'bank_transfer' => ['bank' => 'bri'],
            ]),
            BillingPaymentMethod::Qris => array_merge($base, [
                'payment_type' => 'qris',
                'qris' => ['acquirer' => 'gopay'],
            ]),
            BillingPaymentMethod::Gopay => array_merge($base, [
                'payment_type' => 'gopay',
                'gopay' => [
                    'enable_callback' => true,
                    'callback_url' => config('creativepos.payment.callback_urls.midtrans'),
                ],
            ]),
            BillingPaymentMethod::Ovo => array_merge($base, [
                'payment_type' => 'echannel',
                'echannel' => [
                    'bill_info1' => 'Payment',
                    'bill_info2' => $invoice->invoice_number,
                ],
            ]),
            BillingPaymentMethod::Dana => array_merge($base, [
                'payment_type' => 'dana',
                'dana' => [
                    'callback_url' => config('creativepos.payment.callback_urls.midtrans'),
                ],
            ]),
            default => throw new \InvalidArgumentException('Unsupported Midtrans payment method.'),
        };
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    protected function extractInstructions(BillingPaymentMethod $method, array $data): array
    {
        $instructions = [
            'provider' => 'midtrans',
            'method' => $method->value,
            'transaction_id' => $data['transaction_id'] ?? null,
            'status' => $data['transaction_status'] ?? 'pending',
        ];

        if ($method->value === 'qris' && isset($data['actions'])) {
            foreach ($data['actions'] as $action) {
                if (($action['name'] ?? '') === 'generate-qr-code') {
                    $instructions['qr_url'] = $action['url'] ?? null;
                }
            }
            $instructions['qr_string'] = $data['qr_string'] ?? null;
        }

        if (isset($data['va_numbers'][0])) {
            $instructions['va_number'] = $data['va_numbers'][0]['va_number'] ?? null;
            $instructions['bank'] = $data['va_numbers'][0]['bank'] ?? null;
        }

        if (isset($data['biller_code'], $data['bill_key'])) {
            $instructions['biller_code'] = $data['biller_code'];
            $instructions['bill_key'] = $data['bill_key'];
        }

        if (isset($data['actions'])) {
            foreach ($data['actions'] as $action) {
                if (($action['name'] ?? '') === 'deeplink-redirect') {
                    $instructions['deeplink'] = $action['url'] ?? null;
                }
                if (($action['name'] ?? '') === 'generate-qr-code' && ! isset($instructions['qr_url'])) {
                    $instructions['qr_url'] = $action['url'] ?? null;
                }
            }
        }

        if (isset($data['expiry_time'])) {
            $instructions['expires_at'] = $data['expiry_time'];
        }

        return $instructions;
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
    protected function mockCharge(BillingInvoice $invoice, BillingPaymentMethod $method): array
    {
        $orderId = $this->buildOrderId($invoice);
        $expiresAt = now()->addHours(24)->toIso8601String();

        $instructions = [
            'provider' => 'midtrans',
            'method' => $method->value,
            'mode' => 'sandbox_mock',
            'transaction_id' => 'MOCK-'.Str::upper(Str::random(8)),
            'snap_token' => 'MOCK-SNAP-'.Str::upper(Str::random(24)),
            'status' => 'pending',
            'expires_at' => $expiresAt,
        ];

        if (str_starts_with($method->value, 'va_')) {
            $bank = strtoupper(str_replace('va_', '', $method->value));
            $instructions['bank'] = $bank;
            $instructions['va_number'] = '8808'.random_int(1000000000, 9999999999);
        }

        if ($method === BillingPaymentMethod::Qris) {
            $instructions['qr_string'] = '00020101021126550014ID.CO.QRIS.WWW011893600'.$invoice->invoice_number;
            $instructions['qr_url'] = null;
        }

        if (in_array($method, [BillingPaymentMethod::Gopay, BillingPaymentMethod::Dana], true)) {
            $instructions['deeplink'] = 'https://sandbox.midtrans.com/mock/'.$method->value;
        }

        if ($method === BillingPaymentMethod::Ovo) {
            $instructions['biller_code'] = '70012';
            $instructions['bill_key'] = (string) random_int(1000000000, 9999999999);
        }

        return [
            'gateway_order_id' => $orderId,
            'payment_url' => $instructions['deeplink'] ?? null,
            'payment_instructions' => $instructions,
            'payment_expires_at' => $expiresAt,
            'gateway_metadata' => ['mock' => true],
        ];
    }

    protected function baseUrl(): string
    {
        return config('creativepos.payment.midtrans.is_production')
            ? 'https://api.midtrans.com'
            : 'https://api.sandbox.midtrans.com';
    }
}