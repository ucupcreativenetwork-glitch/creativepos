<?php

namespace App\Modules\Delivery\Models;

use App\Modules\Loyalty\Models\Member;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DeliveryOrder extends Model
{
    use BelongsToTenant;
    use HasUuid;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'delivery_number',
        'outlet_id',
        'driver_id',
        'member_id',
        'delivery_zone_id',
        'customer_name',
        'customer_phone',
        'delivery_address',
        'delivery_city',
        'delivery_notes',
        'status',
        'subtotal',
        'shipping_fee',
        'total_amount',
        'distance_km',
        'estimated_minutes',
        'assigned_at',
        'picked_up_at',
        'delivered_at',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'decimal:2',
            'shipping_fee' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'distance_km' => 'decimal:2',
            'estimated_minutes' => 'integer',
            'assigned_at' => 'datetime',
            'picked_up_at' => 'datetime',
            'delivered_at' => 'datetime',
        ];
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(DeliveryDriver::class, 'driver_id');
    }

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }

    public function zone(): BelongsTo
    {
        return $this->belongsTo(DeliveryZone::class, 'delivery_zone_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(DeliveryOrderItem::class);
    }

    public function trackingPoints(): HasMany
    {
        return $this->hasMany(DeliveryTrackingPoint::class);
    }
}