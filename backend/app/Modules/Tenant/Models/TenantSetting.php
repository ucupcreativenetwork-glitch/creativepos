<?php

namespace App\Modules\Tenant\Models;

use App\Modules\Platform\Models\Tenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TenantSetting extends Model
{
    protected $fillable = [
        'tenant_id',
        'business_name',
        'business_type',
        'logo_url',
        'primary_color',
        'service_charge_rate',
        'tax_rate',
        'timezone',
        'currency',
        'setup_completed',
        'onboarding_progress',
        'enabled_payment_methods',
        'feature_reservations',
        'feature_delivery',
        'feature_qr_menu',
    ];

    protected function casts(): array
    {
        return [
            'service_charge_rate' => 'decimal:2',
            'tax_rate' => 'decimal:2',
            'setup_completed' => 'boolean',
            'onboarding_progress' => 'array',
            'enabled_payment_methods' => 'array',
            'feature_reservations' => 'boolean',
            'feature_delivery' => 'boolean',
            'feature_qr_menu' => 'boolean',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}