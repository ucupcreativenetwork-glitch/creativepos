<?php

namespace App\Modules\Notification\Events;

use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\ProductStock;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class LowStockDetectedEvent
{
    use Dispatchable;
    use SerializesModels;

    public function __construct(
        public readonly Product $product,
        public readonly ProductStock $stock,
        public readonly float $quantity,
        public readonly int $minStock,
        public readonly ?string $dedupKey = null,
    ) {}
}