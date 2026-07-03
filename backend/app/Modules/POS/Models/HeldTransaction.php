<?php

namespace App\Modules\POS\Models;

use App\Models\User;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class HeldTransaction extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'outlet_id',
        'cashier_id',
        'reference_name',
        'table_id',
        'member_id',
        'subtotal',
        'held_at',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'decimal:2',
            'held_at' => 'datetime',
        ];
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function cashier(): BelongsTo
    {
        return $this->belongsTo(User::class, 'cashier_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(HeldTransactionItem::class);
    }
}