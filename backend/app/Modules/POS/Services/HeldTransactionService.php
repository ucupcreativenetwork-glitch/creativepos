<?php

namespace App\Modules\POS\Services;

use App\Models\User;
use App\Modules\POS\Models\HeldTransaction;
use App\Modules\POS\Models\HeldTransactionItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class HeldTransactionService
{
    public function list(?int $outletId = null): Collection
    {
        return HeldTransaction::query()
            ->with(['items.product:id,name,sku,base_price,image_url'])
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->orderByDesc('held_at')
            ->get();
    }

    public function create(array $data, User $user): HeldTransaction
    {
        return DB::transaction(function () use ($data, $user) {
            $items = $this->normalizeItems($data['items']);
            $subtotal = collect($items)->sum(fn ($item) => $item['unit_price'] * $item['quantity']);

            $held = HeldTransaction::query()->create([
                'tenant_id' => tenant('id'),
                'outlet_id' => $data['outlet_id'],
                'cashier_id' => $user->id,
                'reference_name' => $data['reference_name'],
                'table_id' => $data['table_id'] ?? null,
                'member_id' => $data['member_id'] ?? null,
                'subtotal' => round($subtotal, 2),
                'held_at' => now(),
            ]);

            foreach ($items as $item) {
                HeldTransactionItem::query()->create([
                    'held_transaction_id' => $held->id,
                    ...$item,
                ]);
            }

            return $held->load(['items.product:id,name,sku,base_price,image_url']);
        });
    }

    public function resume(HeldTransaction $held): array
    {
        $held->load(['items.product:id,name,sku,base_price,image_url,track_stock']);

        $payload = [
            'id' => $held->id,
            'reference_name' => $held->reference_name,
            'outlet_id' => $held->outlet_id,
            'table_id' => $held->table_id,
            'member_id' => $held->member_id,
            'subtotal' => (float) $held->subtotal,
            'held_at' => $held->held_at?->toIso8601String(),
            'items' => $held->items->map(fn (HeldTransactionItem $item) => $this->formatItem($item))->all(),
        ];

        $held->items()->delete();
        $held->delete();

        return $payload;
    }

    public function delete(HeldTransaction $held): void
    {
        $held->delete();
    }

    /**
     * @param  array<int, array<string, mixed>>  $rawItems
     * @return array<int, array<string, mixed>>
     */
    protected function normalizeItems(array $rawItems): array
    {
        return collect($rawItems)->map(function (array $item) {
            $meta = [
                'product_name' => $item['product_name'] ?? null,
                'sku' => $item['sku'] ?? null,
                'modifiers' => $item['modifiers'] ?? [],
            ];

            return [
                'product_id' => $item['product_id'],
                'variant_id' => $item['variant_id'] ?? null,
                'quantity' => $item['quantity'],
                'unit_price' => $item['unit_price'],
                'notes' => json_encode(array_filter($meta)),
            ];
        })->all();
    }

    protected function formatItem(HeldTransactionItem $item): array
    {
        $meta = json_decode($item->notes ?? '{}', true) ?: [];

        return [
            'product_id' => $item->product_id,
            'product_name' => $meta['product_name'] ?? $item->product?->name,
            'sku' => $meta['sku'] ?? $item->product?->sku,
            'quantity' => (float) $item->quantity,
            'unit_price' => (float) $item->unit_price,
            'modifiers' => $meta['modifiers'] ?? [],
            'product' => $item->product ? [
                'id' => $item->product->id,
                'name' => $item->product->name,
                'sku' => $item->product->sku,
                'base_price' => (float) $item->product->base_price,
                'image_url' => $item->product->image_url,
            ] : null,
        ];
    }
}