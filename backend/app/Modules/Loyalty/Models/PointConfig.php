<?php

namespace App\Modules\Loyalty\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;

class PointConfig extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'earn_amount',
        'earn_points',
        'redeem_points',
        'redeem_value',
        'min_redeem_points',
        'point_expiry_days',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'earn_amount' => 'decimal:2',
            'redeem_value' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }
}