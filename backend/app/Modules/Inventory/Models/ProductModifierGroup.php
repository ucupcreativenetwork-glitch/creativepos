<?php

namespace App\Modules\Inventory\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ProductModifierGroup extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'product_id',
        'name',
        'is_required',
        'min_select',
        'max_select',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'is_required' => 'boolean',
            'min_select' => 'integer',
            'max_select' => 'integer',
            'sort_order' => 'integer',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function modifiers(): HasMany
    {
        return $this->hasMany(ProductModifier::class, 'group_id');
    }

    public function activeModifiers(): HasMany
    {
        return $this->modifiers()->where('is_active', true)->orderBy('sort_order');
    }
}