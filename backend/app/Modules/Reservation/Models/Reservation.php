<?php

namespace App\Modules\Reservation\Models;

use App\Modules\Loyalty\Models\Member;
use App\Modules\Order\Models\Table;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Reservation extends Model
{
    use BelongsToTenant;
    use HasUuid;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'reservation_number',
        'outlet_id',
        'member_id',
        'table_id',
        'customer_name',
        'customer_phone',
        'customer_email',
        'guest_count',
        'reservation_date',
        'reservation_time',
        'status',
        'notes',
        'confirmed_at',
        'arrived_at',
        'cancelled_at',
    ];

    protected function casts(): array
    {
        return [
            'reservation_date' => 'date',
            'guest_count' => 'integer',
            'confirmed_at' => 'datetime',
            'arrived_at' => 'datetime',
            'cancelled_at' => 'datetime',
        ];
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }

    public function table(): BelongsTo
    {
        return $this->belongsTo(Table::class);
    }

    public function statusHistories(): HasMany
    {
        return $this->hasMany(ReservationStatusHistory::class);
    }
}