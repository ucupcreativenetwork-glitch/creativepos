<?php

namespace App\Modules\Delivery\Models;

use App\Models\User;
use App\Modules\Tenant\Models\Outlet;
use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DeliveryDriver extends Model
{
    use BelongsToTenant;
    use HasUuid;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'user_id',
        'outlet_id',
        'vehicle_type',
        'vehicle_plate',
        'is_active',
        'is_available',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'is_available' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function outlet(): BelongsTo
    {
        return $this->belongsTo(Outlet::class);
    }

    public function deliveryOrders(): HasMany
    {
        return $this->hasMany(DeliveryOrder::class, 'driver_id');
    }
}