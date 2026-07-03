<?php

namespace Database\Seeders;

use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Billing\Models\BillingPayment;
use App\Modules\Platform\Models\Subscription;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Database\Seeder;

class BillingDemoSeeder extends Seeder
{
    public function run(): void
    {
        $tenants = Tenant::query()->get();

        foreach ($tenants as $tenant) {
            set_tenant($tenant);
            $this->seedForTenant($tenant);
        }
    }

    protected function seedForTenant(Tenant $tenant): void
    {
        if (BillingInvoice::query()->where('tenant_id', $tenant->id)->exists()) {
            return;
        }

        $subscription = Subscription::query()
            ->where('tenant_id', $tenant->id)
            ->where('status', 'active')
            ->latest()
            ->first();

        if (! $subscription) {
            return;
        }

        $package = $subscription->package;
        $amount = $subscription->billing_cycle === 'yearly'
            ? (float) $package->price_yearly
            : (float) $package->price_monthly;
        $taxAmount = round($amount * 0.11, 2);
        $totalAmount = $amount + $taxAmount;

        $invoices = [
            [
                'invoice_number' => 'INV-'.now()->subMonths(2)->format('Y').'-'.str_pad((string) $tenant->id, 5, '0', STR_PAD_LEFT).'01',
                'status' => 'paid',
                'due_date' => now()->subMonths(2)->addDays(14)->toDateString(),
                'paid_at' => now()->subMonths(2)->addDays(7),
                'period_start' => now()->subMonths(2)->startOfMonth()->toDateString(),
                'period_end' => now()->subMonths(2)->endOfMonth()->toDateString(),
            ],
            [
                'invoice_number' => 'INV-'.now()->subMonth()->format('Y').'-'.str_pad((string) $tenant->id, 5, '0', STR_PAD_LEFT).'02',
                'status' => 'paid',
                'due_date' => now()->subMonth()->addDays(14)->toDateString(),
                'paid_at' => now()->subMonth()->addDays(5),
                'period_start' => now()->subMonth()->startOfMonth()->toDateString(),
                'period_end' => now()->subMonth()->endOfMonth()->toDateString(),
            ],
            [
                'invoice_number' => 'INV-'.now()->format('Y').'-'.str_pad((string) $tenant->id, 5, '0', STR_PAD_LEFT).'03',
                'status' => 'sent',
                'due_date' => now()->addDays(14)->toDateString(),
                'paid_at' => null,
                'period_start' => now()->startOfMonth()->toDateString(),
                'period_end' => now()->endOfMonth()->toDateString(),
            ],
        ];

        foreach ($invoices as $invoiceData) {
            $invoice = BillingInvoice::query()->create([
                'tenant_id' => $tenant->id,
                'subscription_id' => $subscription->id,
                'invoice_number' => $invoiceData['invoice_number'],
                'amount' => $amount,
                'tax_amount' => $taxAmount,
                'total_amount' => $totalAmount,
                'status' => $invoiceData['status'],
                'due_date' => $invoiceData['due_date'],
                'paid_at' => $invoiceData['paid_at'],
                'period_start' => $invoiceData['period_start'],
                'period_end' => $invoiceData['period_end'],
            ]);

            if ($invoice->status === 'paid') {
                BillingPayment::query()->create([
                    'invoice_id' => $invoice->id,
                    'tenant_id' => $tenant->id,
                    'amount' => $totalAmount,
                    'payment_method' => 'bank_transfer',
                    'transaction_ref' => 'PAY-'.$invoice->invoice_number,
                    'paid_at' => $invoice->paid_at,
                    'created_at' => $invoice->paid_at,
                ]);
            }
        }
    }
}