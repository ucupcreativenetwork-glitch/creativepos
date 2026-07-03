<?php

namespace App\Modules\Loyalty\Models;

use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use App\Shared\Traits\Searchable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Member extends Model
{
    use BelongsToTenant;
    use HasUuid;
    use Searchable;
    use SoftDeletes;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'member_code',
        'qr_token',
        'name',
        'email',
        'phone',
        'birthday',
        'tier_id',
        'status',
        'total_spend',
        'visit_count',
        'last_visit_at',
    ];

    protected function casts(): array
    {
        return [
            'total_spend' => 'decimal:2',
            'birthday' => 'date',
            'last_visit_at' => 'datetime',
        ];
    }

    public function tier(): BelongsTo
    {
        return $this->belongsTo(TierConfig::class, 'tier_id');
    }

    public function points(): HasOne
    {
        return $this->hasOne(MemberPoint::class);
    }

    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class);
    }
}