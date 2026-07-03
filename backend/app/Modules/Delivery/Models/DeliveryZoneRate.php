<?php

namespace App\Modules\Delivery\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeliveryZoneRate extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'delivery_zone_id',
        'min_distance_km',
        'max_distance_km',
        'base_fee',
        'fee_per_km',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'min_distance_km' => 'decimal:2',
            'max_distance_km' => 'decimal:2',
            'base_fee' => 'decimal:2',
            'fee_per_km' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function zone(): BelongsTo
    {
        return $this->belongsTo(DeliveryZone::class, 'delivery_zone_id');
    }
}