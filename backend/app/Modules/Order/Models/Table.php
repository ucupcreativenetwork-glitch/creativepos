<?php

namespace App\Modules\Order\Models;

use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Table extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'outlet_id',
        'area_id',
        'table_number',
        'name',
        'capacity',
        'status',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function area(): BelongsTo
    {
        return $this->belongsTo(TableArea::class, 'area_id');
    }

    public function qrCode(): HasOne
    {
        return $this->hasOne(TableQrCode::class);
    }
}