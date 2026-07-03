<?php

use App\Modules\POS\Models\SalePayment;
use App\Modules\POS\Models\SaleTransaction;

describe('POS Payment', function (): void {
    it('accepts split payment between cash and gopay', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $cashier = $this->createUser('cashier', $tenant);
        $product = $this->createProduct(['base_price' => 75_000, 'stock' => 5], $tenant);
        $this->openShift($cashier);

        $this->actingAsTenantUser($cashier, $tenant);
        $response = $this->postTransaction($cashier, [
            'outlet_id' => $cashier->outlet_id,
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
            ],
            'payments' => [
                [
                    'payment_method_id' => $this->paymentMethodId('cash'),
                    'amount' => 40_000,
                ],
                [
                    'payment_method_id' => $this->paymentMethodId('gopay'),
                    'amount' => 35_000,
                ],
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.grand_total', 75_000);

        $transaction = SaleTransaction::query()->with('payments.paymentMethod')->first();
        expect($transaction->payments)->toHaveCount(2);

        $codes = $transaction->payments
            ->map(fn (SalePayment $payment) => $payment->paymentMethod->code)
            ->sort()
            ->values()
            ->all();

        expect($codes)->toBe(['cash', 'gopay']);
    });

    it('calculates cash change correctly and rejects mismatched payment totals', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $cashier = $this->createUser('cashier', $tenant);
        $product = $this->createProduct(['base_price' => 75_000, 'stock' => 5], $tenant);
        $this->openShift($cashier);

        $grandTotal = 75_000;
        $cashTendered = 100_000;
        $cashApplied = $grandTotal;

        expect(calculateCashChange($cashTendered, $cashApplied))->toEqual(25_000);

        $this->actingAsTenantUser($cashier, $tenant);
        $success = $this->postTransaction($cashier, [
            'outlet_id' => $cashier->outlet_id,
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
            ],
            'payments' => [
                [
                    'payment_method_id' => $this->paymentMethodId('cash'),
                    'amount' => $cashApplied,
                ],
            ],
        ]);

        $success->assertCreated();

        $fail = $this->postTransaction($cashier, [
            'outlet_id' => $cashier->outlet_id,
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
            ],
            'payments' => [
                [
                    'payment_method_id' => $this->paymentMethodId('cash'),
                    'amount' => 70_000,
                ],
            ],
        ], (string) \Illuminate\Support\Str::uuid());

        $fail->assertStatus(422)
            ->assertJsonPath('message', 'Total pembayaran harus sama dengan grand total.');
    });
});