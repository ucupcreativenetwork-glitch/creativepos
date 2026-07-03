<?php

namespace App\Modules\Reservation\Models;

use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ReservationTimeSlot extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'outlet_id',
        'day_of_week',
        'start_time',
        'end_time',
        'capacity',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'day_of_week' => 'integer',
            'capacity' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }
}