<?php

namespace App\Modules\Platform\Models;

use App\Models\User;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;

class Tenant extends Model
{
    use HasUuid;
    use SoftDeletes;

    protected $fillable = [
        'uuid',
        'name',
        'slug',
        'email',
        'phone',
        'logo_url',
        'address',
        'npwp',
        'status',
        'trial_ends_at',
        'suspended_at',
        'terminated_at',
        'timezone',
        'currency',
        'locale',
    ];

    protected function casts(): array
    {
        return [
            'trial_ends_at' => 'datetime',
            'suspended_at' => 'datetime',
            'terminated_at' => 'datetime',
        ];
    }

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function activeSubscription(): HasOne
    {
        return $this->hasOne(Subscription::class)
            ->where('status', 'active')
            ->latestOfMany();
    }

    public function trialPackage(): ?Package
    {
        return Package::query()
            ->where('slug', config('creativepos.packages.default_slug', 'starter'))
            ->first();
    }

    public function isOnTrial(): bool
    {
        return $this->status === 'trial'
            && ($this->trial_ends_at === null || $this->trial_ends_at->isFuture());
    }
}