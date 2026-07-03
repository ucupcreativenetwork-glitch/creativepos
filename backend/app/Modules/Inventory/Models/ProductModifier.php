<?php

namespace App\Modules\Inventory\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductModifier extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'group_id',
        'name',
        'price_adjustment',
        'is_default',
        'is_active',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'price_adjustment' => 'decimal:2',
            'is_default' => 'boolean',
            'is_active' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(ProductModifierGroup::class, 'group_id');
    }
}