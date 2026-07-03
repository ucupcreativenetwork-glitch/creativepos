<?php

namespace App\Modules\Order\Models;

use App\Models\User;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TableServiceRequest extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'uuid',
        'tenant_id',
        'outlet_id',
        'table_id',
        'type',
        'status',
        'table_token',
        'table_number',
        'table_area',
        'acknowledged_by',
        'acknowledged_at',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'acknowledged_at' => 'datetime',
            'created_at' => 'datetime',
        ];
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function table(): BelongsTo
    {
        return $this->belongsTo(Table::class);
    }

    public function acknowledgedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'acknowledged_by');
    }
}