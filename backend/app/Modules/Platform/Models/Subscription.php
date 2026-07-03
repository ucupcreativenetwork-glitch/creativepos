<?php

namespace App\Modules\Platform\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Subscription extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'package_id',
        'status',
        'billing_cycle',
        'starts_at',
        'ends_at',
        'next_billing_date',
        'cancelled_at',
        'xendit_customer_id',
        'xendit_recurring_id',
        'auto_renew',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'date',
            'ends_at' => 'date',
            'next_billing_date' => 'date',
            'cancelled_at' => 'datetime',
            'auto_renew' => 'boolean',
        ];
    }

    public function package(): BelongsTo
    {
        return $this->belongsTo(Package::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active' && $this->ends_at->isFuture();
    }
}