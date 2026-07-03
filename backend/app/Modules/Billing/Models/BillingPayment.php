<?php

namespace App\Modules\Billing\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BillingPayment extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'invoice_id',
        'tenant_id',
        'amount',
        'payment_method',
        'payment_gateway',
        'status',
        'transaction_ref',
        'gateway_response',
        'paid_at',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'gateway_response' => 'array',
            'paid_at' => 'datetime',
            'created_at' => 'datetime',
        ];
    }

    public function invoice(): BelongsTo
    {
        return $this->belongsTo(BillingInvoice::class, 'invoice_id');
    }
}