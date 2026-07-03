<?php

describe('Product Recipe', function (): void {
    it('allows saving an empty ingredients list to clear a recipe', function (): void {
        $tenant = $this->createTenant();
        $user = $this->actingAsTenantUser(role: 'owner', tenant: $tenant);
        $product = $this->createProduct(tenant: $tenant);

        $this->putJson("/api/v1/inventory/products/{$product->uuid}/recipe", [
            'ingredients' => [],
        ])->assertOk()
            ->assertJsonPath('data.ingredients', []);
    });

    it('syncs recipe ingredients for a product', function (): void {
        $tenant = $this->createTenant();
        $user = $this->actingAsTenantUser(role: 'owner', tenant: $tenant);
        $product = $this->createProduct(tenant: $tenant);

        $rawMaterial = \App\Modules\Inventory\Models\RawMaterial::query()->create([
            'tenant_id' => $tenant->id,
            'name' => 'Gula',
            'unit' => 'gram',
            'cost_per_unit' => 10,
            'min_stock' => 0,
            'current_stock' => 1000,
            'is_active' => true,
        ]);

        $this->putJson("/api/v1/inventory/products/{$product->uuid}/recipe", [
            'ingredients' => [
                [
                    'raw_material_id' => $rawMaterial->id,
                    'quantity_needed' => 20,
                    'unit' => 'gram',
                ],
            ],
        ])->assertOk()
            ->assertJsonPath('data.ingredients.0.raw_material_id', $rawMaterial->id);
    });
});