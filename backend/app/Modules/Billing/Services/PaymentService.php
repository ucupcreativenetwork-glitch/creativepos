<?php

namespace App\Modules\Billing\Services;

use App\Modules\Billing\Enums\BillingPaymentMethod;
use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Billing\Models\BillingPayment;
use App\Modules\Billing\Services\Gateways\MidtransGateway;
use App\Modules\Billing\Services\Gateways\XenditGateway;
use App\Modules\Platform\Models\Subscription;
use Illuminate\Support\Facades\DB;

class PaymentService
{
    public function __construct(
        private readonly MidtransGateway $midtrans,
        private readonly XenditGateway $xendit,
    ) {}

    /**
     * @return list<array{code: string, label: string, gateway: string, recurring: bool}>
     */
    public function listPaymentMethods(): array
    {
        return array_map(
            fn (BillingPaymentMethod $method) => [
                'code' => $method->value,
                'label' => $method->label(),
                'gateway' => $method->gateway(),
                'recurring' => $method->isRecurringCapable(),
            ],
            BillingPaymentMethod::available(),
        );
    }

    /**
     * @return array<string, mixed>
     */
    public function initiatePayment(BillingInvoice $invoice, string $paymentMethodCode, bool $enableRecurring = false): array
    {
        if (in_array($invoice->status, ['paid', 'cancelled'], true)) {
            throw new \InvalidArgumentException('Invoice tidak dapat dibayar.');
        }

        $method = BillingPaymentMethod::tryFromString($paymentMethodCode);
        if ($method === null) {
            throw new \InvalidArgumentException('Metode pembayaran tidak valid.');
        }

        if ($method === BillingPaymentMethod::Cod) {
            return $this->initiateCod($invoice);
        }

        $tenant = tenant();
        if ($tenant === null) {
            throw new \RuntimeException('Tenant context tidak ditemukan.');
        }

        if ($method === BillingPaymentMethod::CreditCard) {
            $charge = $this->xendit->createInvoiceCharge($invoice, $tenant, $enableRecurring);
            $gateway = 'xendit';
        } else {
            $charge = $this->midtrans->createCharge($invoice, $method, $tenant);
            $gateway = 'midtrans';
        }

        $invoice->update([
            'payment_gateway' => $gateway,
            'payment_method' => $method->value,
            'gateway_order_id' => $charge['gateway_order_id'],
            'payment_status' => 'pending',
            'payment_url' => $charge['payment_url'],
            'payment_instructions' => $charge['payment_instructions'],
            'payment_expires_at' => $charge['payment_expires_at'],
            'gateway_metadata' => $charge['gateway_metadata'],
            'status' => $invoice->status === 'draft' ? 'sent' : $invoice->status,
        ]);

        if ($enableRecurring && $method === BillingPaymentMethod::CreditCard && $invoice->subscription_id) {
            $subscription = Subscription::query()->find($invoice->subscription_id);
            if ($subscription) {
                $subscription->update(['auto_renew' => true]);
            }
        }

        return $this->formatPaymentResponse($invoice->fresh());
    }

    /**
     * @return array<string, mixed>
     */
    public function setupRecurringSubscription(): array
    {
        $subscription = Subscription::query()
            ->with('package:id,name,slug,price_monthly,price_yearly')
            ->where('status', 'active')
            ->latest()
            ->first();

        if ($subscription === null) {
            throw new \InvalidArgumentException('Tidak ada langganan aktif.');
        }

        $tenant = tenant();
        if ($tenant === null) {
            throw new \RuntimeException('Tenant context tidak ditemukan.');
        }

        $setup = $this->xendit->setupRecurring($subscription, $tenant);

        $subscription->update([
            'xendit_customer_id' => $setup['customer_id'] ?? $subscription->xendit_customer_id,
            'xendit_recurring_id' => $setup['recurring_id'] ?? $subscription->xendit_recurring_id,
            'auto_renew' => true,
        ]);

        return [
            'subscription_id' => $subscription->id,
            'auto_renew' => true,
            'payment_url' => $setup['payment_url'] ?? null,
            'provider' => 'xendit',
            'mode' => $setup['mode'] ?? 'live',
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function getPaymentStatus(BillingInvoice $invoice): array
    {
        return $this->formatPaymentResponse($invoice);
    }

    public function markInvoicePaid(
        BillingInvoice $invoice,
        string $gateway,
        string $paymentMethod,
        ?string $transactionRef,
        array $gatewayResponse = [],
    ): BillingInvoice {
        return DB::transaction(function () use ($invoice, $gateway, $paymentMethod, $transactionRef, $gatewayResponse) {
            $invoice = BillingInvoice::query()
                ->withoutGlobalScopes()
                ->lockForUpdate()
                ->findOrFail($invoice->id);

            if ($invoice->status === 'paid') {
                return $invoice;
            }

            $paidAt = now();

            $invoice->update([
                'status' => 'paid',
                'payment_status' => 'paid',
                'paid_at' => $paidAt,
            ]);

            BillingPayment::query()->create([
                'invoice_id' => $invoice->id,
                'tenant_id' => $invoice->tenant_id,
                'amount' => $invoice->total_amount,
                'payment_method' => $paymentMethod,
                'payment_gateway' => $gateway,
                'status' => 'completed',
                'transaction_ref' => $transactionRef,
                'gateway_response' => $gatewayResponse,
                'paid_at' => $paidAt,
                'created_at' => $paidAt,
            ]);

            if ($invoice->subscription_id) {
                $subscription = Subscription::query()
                    ->withoutGlobalScopes()
                    ->find($invoice->subscription_id);

                if ($subscription) {
                    $cycle = $subscription->billing_cycle === 'yearly' ? 'year' : 'month';
                    $subscription->update([
                        'status' => 'active',
                        'next_billing_date' => now()->add(1, $cycle)->toDateString(),
                        'ends_at' => now()->add(1, $cycle)->toDateString(),
                    ]);
                }
            }

            return $invoice->fresh();
        });
    }

    public function updatePaymentStatus(BillingInvoice $invoice, string $paymentStatus): BillingInvoice
    {
        $invoice->update(['payment_status' => $paymentStatus]);

        if ($paymentStatus === 'expired' && $invoice->status === 'sent') {
            $invoice->update(['status' => 'overdue']);
        }

        return $invoice->fresh();
    }

    public function findInvoiceByGatewayOrder(string $orderId): ?BillingInvoice
    {
        return BillingInvoice::query()
            ->withoutGlobalScopes()
            ->where('gateway_order_id', $orderId)
            ->first();
    }

    public function findInvoiceByIdFromMetadata(?int $invoiceId): ?BillingInvoice
    {
        if ($invoiceId === null) {
            return null;
        }

        return BillingInvoice::query()
            ->withoutGlobalScopes()
            ->find($invoiceId);
    }

    /**
     * @return array<string, mixed>
     */
    protected function initiateCod(BillingInvoice $invoice): array
    {
        $invoice->update([
            'payment_gateway' => 'cod',
            'payment_method' => BillingPaymentMethod::Cod->value,
            'gateway_order_id' => 'COD-'.$invoice->invoice_number,
            'payment_status' => 'pending',
            'payment_url' => null,
            'payment_instructions' => [
                'provider' => 'cod',
                'method' => 'cod',
                'message' => 'Tim kami akan menghubungi Anda untuk konfirmasi pembayaran COD.',
            ],
            'payment_expires_at' => $invoice->due_date?->endOfDay()->toIso8601String(),
            'gateway_metadata' => ['manual_confirmation' => true],
            'status' => $invoice->status === 'draft' ? 'sent' : $invoice->status,
        ]);

        return $this->formatPaymentResponse($invoice->fresh());
    }

    /**
     * @return array<string, mixed>
     */
    protected function formatPaymentResponse(BillingInvoice $invoice): array
    {
        return [
            'invoice_id' => $invoice->id,
            'invoice_number' => $invoice->invoice_number,
            'total_amount' => (float) $invoice->total_amount,
            'status' => $invoice->status,
            'payment_gateway' => $invoice->payment_gateway,
            'payment_method' => $invoice->payment_method,
            'payment_status' => $invoice->payment_status,
            'payment_url' => $invoice->payment_url,
            'payment_instructions' => $invoice->payment_instructions,
            'payment_expires_at' => $invoice->payment_expires_at?->toIso8601String(),
            'gateway_order_id' => $invoice->gateway_order_id,
        ];
    }
}