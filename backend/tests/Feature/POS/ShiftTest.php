<?php

use App\Modules\POS\Models\SaleTransaction;
use App\Modules\POS\Models\Shift;
use App\Modules\Platform\Models\Tenant;

describe('POS Shift', function (): void {
    it('opens and closes a cashier shift', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $cashier = $this->actingAsTenantUser(null, $tenant, 'cashier');

        $openResponse = $this->postJson('/api/v1/pos/shifts/open', [
            'outlet_id' => $cashier->outlet_id,
            'opening_cash' => 150_000,
        ]);

        $openResponse->assertCreated()
            ->assertJsonPath('data.status', 'open');

        $shiftId = $openResponse->json('data.id');
        $shift = Shift::query()->find($shiftId);

        expect($shift)->not->toBeNull()
            ->and((float) $shift->opening_cash)->toEqual(150_000);

        $closeResponse = $this->postJson("/api/v1/pos/shifts/{$shiftId}/close", [
            'closing_cash' => 150_000,
            'notes' => 'Tutup shift test',
        ]);

        $closeResponse->assertOk()
            ->assertJsonPath('data.status', 'closed');

        $shift->refresh();
        expect($shift->status)->toBe('closed')
            ->and($shift->closed_at)->not->toBeNull();
    });

    it('cannot create a transaction without an active shift', function (): void {
        $tenant = $this->createTenant();
        set_tenant($tenant);

        $cashier = $this->createUser('cashier', $tenant);
        $product = $this->createProduct(['stock' => 10], $tenant);

        $this->actingAsTenantUser($cashier, $tenant);
        $response = $this->postTransaction($cashier, [
            'outlet_id' => $cashier->outlet_id,
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
            ->assertJsonPath('message', 'Tidak ada shift aktif. Buka shift terlebih dahulu.');

        expect(SaleTransaction::query()->count())->toBe(0);
        expect(Shift::query()->where('status', 'open')->count())->toBe(0);
    });
});