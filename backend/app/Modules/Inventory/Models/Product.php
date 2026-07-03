<?php

namespace App\Modules\Inventory\Models;

use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use App\Shared\Traits\Searchable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    use BelongsToTenant;
    use HasUuid;
    use Searchable;
    use SoftDeletes;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'category_id',
        'sku',
        'barcode',
        'name',
        'image_url',
        'base_price',
        'cost_price',
        'min_stock',
        'track_stock',
        'is_active',
        'is_available',
        'show_in_pos',
    ];

    protected function casts(): array
    {
        return [
            'base_price' => 'decimal:2',
            'cost_price' => 'decimal:2',
            'track_stock' => 'boolean',
            'is_active' => 'boolean',
            'is_available' => 'boolean',
            'show_in_pos' => 'boolean',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function stocks(): HasMany
    {
        return $this->hasMany(ProductStock::class);
    }

    public function modifierGroups(): HasMany
    {
        return $this->hasMany(ProductModifierGroup::class)->orderBy('sort_order');
    }

    public function recipes(): HasMany
    {
        return $this->hasMany(ProductRecipe::class);
    }
}