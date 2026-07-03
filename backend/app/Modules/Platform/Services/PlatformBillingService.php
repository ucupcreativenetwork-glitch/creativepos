<?php

namespace App\Modules\Platform\Services;

use App\Modules\Billing\Models\BillingInvoice;
use App\Modules\Platform\Models\Package;
use App\Modules\Platform\Models\Subscription;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\DB;

class PlatformBillingService
{
    public function listInvoices(?string $status, ?int $tenantId, int $perPage = 15): LengthAwarePaginator
    {
        return BillingInvoice::query()
            ->withoutGlobalScopes()
            ->with(['subscription.package:id,name,slug'])
            ->when($status, fn ($q) => $q->where('status', $status))
            ->when($tenantId, fn ($q) => $q->where('tenant_id', $tenantId))
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function generateInvoice(array $data): BillingInvoice
    {
        return DB::transaction(function () use ($data) {
            $tenant = Tenant::query()->findOrFail($data['tenant_id']);

            $subscription = isset($data['subscription_id'])
                ? Subscription::query()->withoutGlobalScopes()->findOrFail($data['subscription_id'])
                : Subscription::query()
                    ->withoutGlobalScopes()
                    ->where('tenant_id', $tenant->id)
                    ->where('status', 'active')
                    ->latest()
                    ->first();

            if ($subscription) {
                $package = $subscription->package;
            } elseif (! empty($data['package_id'])) {
                $package = Package::query()->findOrFail($data['package_id']);
            } else {
                throw new \InvalidArgumentException('package_id is required when no active subscription exists.');
            }

            $billingCycle = $subscription?->billing_cycle ?? ($data['billing_cycle'] ?? 'monthly');
            $amount = $billingCycle === 'yearly'
                ? (float) $package->price_yearly
                : (float) $package->price_monthly;

            $taxRate = (float) ($data['tax_rate'] ?? 11);
            $taxAmount = round($amount * ($taxRate / 100), 2);
            $totalAmount = $amount + $taxAmount;

            $periodStart = $data['period_start'] ?? now()->startOfMonth()->toDateString();
            $periodEnd = $data['period_end'] ?? now()->endOfMonth()->toDateString();

            return BillingInvoice::query()->create([
                'tenant_id' => $tenant->id,
                'subscription_id' => $subscription?->id,
                'invoice_number' => $this->generateInvoiceNumber(),
                'amount' => $amount,
                'tax_amount' => $taxAmount,
                'total_amount' => $totalAmount,
                'status' => $data['status'] ?? 'sent',
                'due_date' => $data['due_date'] ?? now()->addDays(14)->toDateString(),
                'period_start' => $periodStart,
                'period_end' => $periodEnd,
            ]);
        });
    }

    protected function generateInvoiceNumber(): string
    {
        $prefix = 'INV-'.now()->format('Y');

        $lastNumber = BillingInvoice::query()
            ->withoutGlobalScopes()
            ->where('invoice_number', 'like', $prefix.'%')
            ->orderByDesc('id')
            ->value('invoice_number');

        $sequence = 1;
        if ($lastNumber && preg_match('/(\d+)$/', $lastNumber, $matches)) {
            $sequence = (int) $matches[1] + 1;
        }

        return $prefix.'-'.str_pad((string) $sequence, 5, '0', STR_PAD_LEFT);
    }
}