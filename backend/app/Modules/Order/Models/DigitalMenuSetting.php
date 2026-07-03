<?php

namespace App\Modules\Order\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;

class DigitalMenuSetting extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'outlet_id',
        'theme_color',
        'welcome_message',
        'show_prices',
        'allow_guest_order',
    ];

    protected function casts(): array
    {
        return [
            'show_prices' => 'boolean',
            'allow_guest_order' => 'boolean',
        ];
    }
}