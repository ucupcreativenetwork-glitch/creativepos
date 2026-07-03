<?php

namespace App\Models;

use App\Modules\Auth\Models\LoginHistory;
use App\Modules\Auth\Models\UserDevice;
use App\Modules\Platform\Models\Tenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasApiTokens;
    use HasFactory;
    use HasRoles;
    use HasUuid;
    use Notifiable;
    use SoftDeletes;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'name',
        'email',
        'phone',
        'password',
        'must_change_password',
        'avatar_url',
        'outlet_id',
        'is_super_admin',
        'status',
        'email_verified_at',
        'two_factor_enabled',
        'two_factor_secret',
        'two_factor_method',
        'last_login_at',
        'last_login_ip',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'two_factor_secret',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'last_login_at' => 'datetime',
            'password' => 'hashed',
            'is_super_admin' => 'boolean',
            'must_change_password' => 'boolean',
            'two_factor_enabled' => 'boolean',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function devices(): HasMany
    {
        return $this->hasMany(UserDevice::class);
    }

    public function loginHistories(): HasMany
    {
        return $this->hasMany(LoginHistory::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function requiresTwoFactor(): bool
    {
        return $this->two_factor_enabled && ! empty($this->two_factor_secret);
    }

    public function requiresPasswordChange(): bool
    {
        return (bool) $this->must_change_password;
    }

    public function getAllPermissionNames(): array
    {
        return $this->getAllPermissions()->pluck('name')->toArray();
    }

    public function sendPasswordResetNotification(#[\SensitiveParameter] $token): void
    {
        $this->notify(new \App\Modules\Notification\Notifications\ResetPasswordNotification($token));
    }

    public function routeNotificationForWhatsapp(): ?string
    {
        return $this->phone;
    }

    /**
     * @return list<string>
     */
    public function routeNotificationForFcm(): array
    {
        return $this->devices()
            ->whereNotNull('fcm_token')
            ->pluck('fcm_token')
            ->filter()
            ->values()
            ->all();
    }
}