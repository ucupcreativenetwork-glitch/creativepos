<?php

namespace App\Modules\Billing\Services;

use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Platform\Models\Subscription;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class BillingService
{
    public function getSubscription(): ?array
    {
        $subscription = Subscription::query()
            ->with([
                'package:id,name,slug,price_monthly,price_yearly,max_outlets,max_users,max_products',
                'package.features:package_id,feature_key,feature_value,is_enabled',
            ])
            ->where('status', 'active')
            ->latest()
            ->first();

        if (! $subscription) {
            return null;
        }

        return [
            'id' => $subscription->id,
            'status' => $subscription->status,
            'billing_cycle' => $subscription->billing_cycle,
            'starts_at' => $subscription->starts_at?->toDateString(),
            'ends_at' => $subscription->ends_at?->toDateString(),
            'next_billing_date' => $subscription->next_billing_date?->toDateString(),
            'package' => $subscription->package ? [
                'id' => $subscription->package->id,
                'name' => $subscription->package->name,
                'slug' => $subscription->package->slug,
                'price_monthly' => (float) $subscription->package->price_monthly,
                'price_yearly' => (float) $subscription->package->price_yearly,
                'max_outlets' => $subscription->package->max_outlets,
                'max_users' => $subscription->package->max_users,
                'max_products' => $subscription->package->max_products,
                'features' => $subscription->package->features
                    ->where('is_enabled', true)
                    ->mapWithKeys(fn ($f) => [$f->feature_key => $f->feature_value])
                    ->all(),
            ] : null,
        ];
    }

    public function listInvoices(int $perPage = 15): LengthAwarePaginator
    {
        return BillingInvoice::query()
            ->with('subscription.package:id,name,slug')
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function getInvoice(BillingInvoice $invoice): array
    {
        $invoice->load(['subscription.package:id,name,slug', 'payments']);

        return [
            'id' => $invoice->id,
            'invoice_number' => $invoice->invoice_number,
            'amount' => (float) $invoice->amount,
            'tax_amount' => (float) $invoice->tax_amount,
            'total_amount' => (float) $invoice->total_amount,
            'status' => $invoice->status,
            'payment_gateway' => $invoice->payment_gateway,
            'payment_method' => $invoice->payment_method,
            'payment_status' => $invoice->payment_status,
            'payment_url' => $invoice->payment_url,
            'payment_instructions' => $invoice->payment_instructions,
            'payment_expires_at' => $invoice->payment_expires_at?->toIso8601String(),
            'due_date' => $invoice->due_date?->toDateString(),
            'paid_at' => $invoice->paid_at?->toIso8601String(),
            'period_start' => $invoice->period_start?->toDateString(),
            'period_end' => $invoice->period_end?->toDateString(),
            'subscription' => $invoice->subscription ? [
                'id' => $invoice->subscription->id,
                'package' => $invoice->subscription->package?->only(['id', 'name', 'slug']),
            ] : null,
            'payments' => $invoice->payments->map(fn ($payment) => [
                'id' => $payment->id,
                'amount' => (float) $payment->amount,
                'payment_method' => $payment->payment_method,
                'payment_gateway' => $payment->payment_gateway,
                'status' => $payment->status,
                'transaction_ref' => $payment->transaction_ref,
                'paid_at' => $payment->paid_at?->toIso8601String(),
            ])->values()->all(),
            'created_at' => $invoice->created_at?->toIso8601String(),
        ];
    }
}