<?php

namespace App\Modules\POS\Models;

use App\Models\User;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class SaleTransaction extends Model
{
    use BelongsToTenant;
    use HasUuid;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'transaction_number',
        'outlet_id',
        'cashier_id',
        'shift_id',
        'member_id',
        'order_type',
        'status',
        'subtotal',
        'discount_total',
        'tax_total',
        'service_charge',
        'grand_total',
        'notes',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'decimal:2',
            'discount_total' => 'decimal:2',
            'tax_total' => 'decimal:2',
            'service_charge' => 'decimal:2',
            'grand_total' => 'decimal:2',
            'completed_at' => 'datetime',
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

    public function shift(): BelongsTo
    {
        return $this->belongsTo(Shift::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(SaleTransactionItem::class, 'transaction_id');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(SalePayment::class, 'transaction_id');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }
}