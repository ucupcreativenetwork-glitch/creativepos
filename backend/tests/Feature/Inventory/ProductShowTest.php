<?php

describe('Inventory Product Show', function (): void {
    it('returns product detail by uuid', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant);
        $product = $this->createProduct(['name' => 'Produk Detail Uji'], $tenant);

        $this->actingAsTenantUser($user, $tenant);

        $response = $this->getJson("/api/v1/inventory/products/{$product->uuid}");

        $response->assertOk()
            ->assertJsonPath('data.uuid', $product->uuid)
            ->assertJsonPath('data.name', 'Produk Detail Uji');
    });

    it('returns product detail by numeric id', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant);
        $product = $this->createProduct(['name' => 'Produk By ID'], $tenant);

        $this->actingAsTenantUser($user, $tenant);

        $response = $this->getJson("/api/v1/inventory/products/{$product->id}");

        $response->assertOk()
            ->assertJsonPath('data.id', $product->id)
            ->assertJsonPath('data.name', 'Produk By ID');
    });

    it('returns 404 for unknown product identifier', function (): void {
        $tenant = $this->createTenant();
        $user = $this->createUser('owner', $tenant);

        $this->actingAsTenantUser($user, $tenant);

        $this->getJson('/api/v1/inventory/products/00000000-0000-0000-0000-000000000099')
            ->assertNotFound();
    });
});