<?php

namespace App\Modules\Notification\Services;

use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductStock;
use App\Modules\Notification\Events\LowStockDetectedEvent;
use Illuminate\Support\Facades\Event;

class StockAlertService
{
    public function checkProductStock(int $productId, int $warehouseId): void
    {
        $stock = ProductStock::query()
            ->with(['product:id,name,sku,min_stock,track_stock', 'warehouse:id,name,code'])
            ->where('product_id', $productId)
            ->where('warehouse_id', $warehouseId)
            ->first();

        if ($stock === null) {
            return;
        }

        $product = $stock->product;

        if ($product === null || ! $product->track_stock) {
            return;
        }

        $quantity = (float) $stock->quantity;
        $minStock = (int) $product->min_stock;

        if ($quantity > $minStock) {
            return;
        }

        $dedupKey = "low_stock:{$productId}:{$warehouseId}";

        if (\App\Modules\Notification\Models\NotificationLog::recentlySent($dedupKey, 24)) {
            return;
        }

        Event::dispatch(new LowStockDetectedEvent(
            product: $product,
            stock: $stock,
            quantity: $quantity,
            minStock: $minStock,
            dedupKey: $dedupKey,
        ));
    }

    public function checkProduct(Product $product): void
    {
        if (! $product->track_stock) {
            return;
        }

        $stocks = ProductStock::query()
            ->where('product_id', $product->id)
            ->get();

        foreach ($stocks as $stock) {
            $this->checkProductStock($product->id, $stock->warehouse_id);
        }
    }
}