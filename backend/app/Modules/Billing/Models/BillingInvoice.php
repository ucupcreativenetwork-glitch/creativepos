<?php

namespace App\Modules\Billing\Models;

use App\Modules\Platform\Models\Subscription;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class BillingInvoice extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'subscription_id',
        'invoice_number',
        'amount',
        'tax_amount',
        'total_amount',
        'status',
        'payment_gateway',
        'payment_method',
        'gateway_order_id',
        'payment_status',
        'payment_url',
        'payment_instructions',
        'payment_expires_at',
        'gateway_metadata',
        'due_date',
        'paid_at',
        'period_start',
        'period_end',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'tax_amount' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'payment_instructions' => 'array',
            'gateway_metadata' => 'array',
            'due_date' => 'date',
            'paid_at' => 'datetime',
            'payment_expires_at' => 'datetime',
            'period_start' => 'date',
            'period_end' => 'date',
        ];
    }

    public function subscription(): BelongsTo
    {
        return $this->belongsTo(Subscription::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(BillingPayment::class, 'invoice_id');
    }
}