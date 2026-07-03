<?php

namespace App\Modules\Loyalty\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MemberPoint extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'member_id',
        'balance',
        'lifetime_earned',
        'lifetime_redeemed',
    ];

    public function member(): BelongsTo
    {
        return $this->belongsTo(Member::class);
    }
}