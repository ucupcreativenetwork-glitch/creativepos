<?php

namespace App\Modules\Platform\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Package extends Model
{
    protected $fillable = [
        'name',
        'slug',
        'description',
        'price_monthly',
        'price_yearly',
        'max_outlets',
        'max_users',
        'max_products',
        'max_members',
        'wa_quota_monthly',
        'trial_days',
        'sort_order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'price_monthly' => 'decimal:2',
            'price_yearly' => 'decimal:2',
            'is_active' => 'boolean',
        ];
    }

    public function features(): HasMany
    {
        return $this->hasMany(PackageFeature::class);
    }

    public function subscriptions(): HasMany
    {
        return $this->hasMany(Subscription::class);
    }

    public function hasFeature(string $featureKey): bool
    {
        return $this->features()
            ->where('feature_key', $featureKey)
            ->where('is_enabled', true)
            ->exists();
    }

    public function getFeatureValue(string $featureKey): ?string
    {
        $feature = $this->features()
            ->where('feature_key', $featureKey)
            ->where('is_enabled', true)
            ->first();

        return $feature?->feature_value;
    }
}