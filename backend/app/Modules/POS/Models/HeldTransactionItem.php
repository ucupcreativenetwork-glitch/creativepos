<?php

namespace App\Modules\POS\Models;

use App\Modules\Inventory\Models\Product;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HeldTransactionItem extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'held_transaction_id',
        'product_id',
        'variant_id',
        'quantity',
        'unit_price',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'quantity' => 'decimal:3',
            'unit_price' => 'decimal:2',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function heldTransaction(): BelongsTo
    {
        return $this->belongsTo(HeldTransaction::class);
    }
}