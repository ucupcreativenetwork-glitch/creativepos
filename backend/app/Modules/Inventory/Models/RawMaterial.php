<?php

namespace App\Modules\Inventory\Models;

use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\Searchable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class RawMaterial extends Model
{
    use BelongsToTenant;
    use Searchable;

    protected $fillable = [
        'tenant_id',
        'name',
        'unit',
        'current_stock',
        'min_stock',
        'cost_per_unit',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'current_stock' => 'decimal:3',
            'min_stock' => 'decimal:3',
            'cost_per_unit' => 'decimal:4',
            'is_active' => 'boolean',
        ];
    }

    public function recipes(): HasMany
    {
        return $this->hasMany(ProductRecipe::class);
    }

    public function isLowStock(): bool
    {
        return (float) $this->current_stock <= (float) $this->min_stock;
    }
}