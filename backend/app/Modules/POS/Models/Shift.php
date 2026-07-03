<?php

namespace App\Modules\POS\Models;

use App\Models\User;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Shift extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'outlet_id',
        'cashier_id',
        'shift_number',
        'status',
        'opening_cash',
        'closing_cash',
        'expected_cash',
        'cash_difference',
        'total_sales',
        'total_transactions',
        'opened_at',
        'closed_at',
        'closed_by',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'opening_cash' => 'decimal:2',
            'closing_cash' => 'decimal:2',
            'expected_cash' => 'decimal:2',
            'cash_difference' => 'decimal:2',
            'total_sales' => 'decimal:2',
            'opened_at' => 'datetime',
            'closed_at' => 'datetime',
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

    public function transactions(): HasMany
    {
        return $this->hasMany(SaleTransaction::class);
    }
}