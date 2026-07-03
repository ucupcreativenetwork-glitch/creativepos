<?php

use App\Modules\Inventory\Models\Product;
use App\Modules\POS\Models\SaleTransaction;

describe('Tenant Isolation', function (): void {
    it('prevents tenant A user from accessing tenant B resources (IDOR)', function (): void {
        $tenantA = $this->createTenant(['name' => 'Tenant A', 'slug' => 'tenant-a-'.uniqid()]);
        $tenantB = $this->createTenant(['name' => 'Tenant B', 'slug' => 'tenant-b-'.uniqid()]);

        set_tenant($tenantA);
        $userA = $this->createUser('owner', $tenantA);
        $productA = $this->createProduct(['name' => 'Produk A'], $tenantA);

        set_tenant($tenantB);
        $cashierB = $this->createUser('cashier', $tenantB);
        $productB = $this->createProduct(['name' => 'Produk B'], $tenantB);
        $shiftB = $this->openShift($cashierB);

        $this->actingAsTenantUser($userA, $tenantA);

        $productResponse = $this->getJson("/api/v1/inventory/products/{$productB->uuid}");
        $productResponse->assertNotFound();

        $listResponse = $this->getJson('/api/v1/inventory/products');
        $listResponse->assertOk();

        $uuids = collect($listResponse->json('data'))->pluck('uuid')->all();
        expect($uuids)->toContain($productA->uuid)
            ->and($uuids)->not->toContain($productB->uuid);

        set_tenant($tenantB);
        $this->actingAsTenantUser($cashierB, $tenantB);
        $this->postTransaction($cashierB, [
            'outlet_id' => $cashierB->outlet_id,
            'shift_id' => $shiftB->id,
            'items' => [
                ['product_id' => $productB->id, 'quantity' => 1],
            ],
            'payments' => [
                [
                    'payment_method_id' => $this->paymentMethodId('cash'),
                    'amount' => (float) $productB->base_price,
                ],
            ],
        ]);

        $transactionB = SaleTransaction::query()->withoutGlobalScopes()->where('tenant_id', $tenantB->id)->first();
        expect($transactionB)->not->toBeNull();

        set_tenant($tenantA);
        $this->actingAsTenantUser($userA, $tenantA);

        $transactionResponse = $this->getJson("/api/v1/pos/transactions/{$transactionB->uuid}");
        $transactionResponse->assertNotFound();
    });
});