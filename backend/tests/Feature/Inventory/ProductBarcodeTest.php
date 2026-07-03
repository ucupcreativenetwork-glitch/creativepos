<?php

describe('Inventory Product Barcode', function (): void {
    it('generates unique EAN-13 barcode for product', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant);
        $product = $this->createProduct(['barcode' => null], $tenant);

        $this->actingAsTenantUser($user, $tenant);

        $response = $this->postJson("/api/v1/inventory/products/{$product->uuid}/generate-barcode");

        $response->assertOk()
            ->assertJsonPath('success', true);

        $barcode = $response->json('data.barcode');
        expect($barcode)->toMatch('/^\d{13}$/');

        $product->refresh();
        expect($product->barcode)->toBe($barcode);
    });

    it('keeps existing barcode unless forced', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant);
        $product = $this->createProduct([], $tenant);
        $product->update(['barcode' => '8991234567890']);

        $this->actingAsTenantUser($user, $tenant);

        $response = $this->postJson("/api/v1/inventory/products/{$product->id}/generate-barcode");

        $response->assertOk()
            ->assertJsonPath('data.barcode', '8991234567890');
    });
});