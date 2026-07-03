<?php

use App\Modules\Inventory\Models\ProductStock;
use App\Modules\Loyalty\Models\MemberPoint;
use App\Modules\Loyalty\Models\PointTransaction;
use App\Modules\POS\Models\SaleTransaction;
use App\Modules\POS\Models\Shift;
use App\Modules\Platform\Models\Tenant;

describe('POS Transaction', function (): void {
    it('creates a transaction, deducts stock, earns member points, and records shift totals', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $cashier = $this->createUser('cashier', $tenant);
        $product = $this->createProduct(['base_price' => 50_000, 'stock' => 10], $tenant);
        $member = $this->createMember($tenant);
        $shift = $this->openShift($cashier);

        $stockBefore = ProductStock::query()
            ->where('product_id', $product->id)
            ->value('quantity');

        $this->actingAsTenantUser($cashier, $tenant);
        $response = $this->postTransaction($cashier, [
            'outlet_id' => $cashier->outlet_id,
            'member_id' => $member->id,
            'items' => [
                ['product_id' => $product->id, 'quantity' => 2],
            ],
            'payments' => [
                [
                    'payment_method_id' => $this->paymentMethodId('cash'),
                    'amount' => 100_000,
                ],
            ],
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.grand_total', 100_000);

        $transaction = SaleTransaction::query()->first();
        expect($transaction)->not->toBeNull()
            ->and($transaction->shift_id)->toBe($shift->id)
            ->and($transaction->member_id)->toBe($member->id);

        $stockAfter = ProductStock::query()
            ->where('product_id', $product->id)
            ->value('quantity');
        expect((float) $stockAfter)->toBe((float) $stockBefore - 2);

        $points = MemberPoint::query()->where('member_id', $member->id)->value('balance');
        expect($points)->toBeGreaterThan(0);

        expect(PointTransaction::query()->where('member_id', $member->id)->count())->toBe(1);

        $shift->refresh();
        expect($shift->total_transactions)->toBe(1)
            ->and((float) $shift->total_sales)->toEqual(100_000);
    });

    it('fails when stock is insufficient for tracked products', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $cashier = $this->createUser('cashier', $tenant);
        $product = $this->createProduct(['track_stock' => true, 'stock' => 1], $tenant);
        $this->openShift($cashier);

        $this->actingAsTenantUser($cashier, $tenant);
        $response = $this->postTransaction($cashier, [
            'outlet_id' => $cashier->outlet_id,
            'items' => [
                ['product_id' => $product->id, 'quantity' => 5],
            ],
            'payments' => [
                [
                    'payment_method_id' => $this->paymentMethodId('cash'),
                    'amount' => 250_000,
                ],
            ],
        ]);

        $response->assertStatus(422);
        expect(SaleTransaction::query()->count())->toBe(0);
    });

    it('fails when member is inactive', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $cashier = $this->createUser('cashier', $tenant);
        $product = $this->createProduct(['stock' => 10], $tenant);
        $member = $this->createMember($tenant, ['status' => 'inactive']);
        $this->openShift($cashier);

        $this->actingAsTenantUser($cashier, $tenant);
        $response = $this->postTransaction($cashier, [
            'outlet_id' => $cashier->outlet_id,
            'member_id' => $member->id,
            'items' => [
                ['product_id' => $product->id, 'quantity' => 1],
            ],
            'payments' => [
                [
                    'payment_method_id' => $this->paymentMethodId('cash'),
                    'amount' => 50_000,
                ],
            ],
        ]);

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Member tidak aktif.');

        expect(SaleTransaction::query()->count())->toBe(0);
    });
});