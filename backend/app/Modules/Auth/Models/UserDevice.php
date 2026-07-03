<?php

namespace App\Modules\Auth\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserDevice extends Model
{
    protected $fillable = [
        'user_id',
        'device_name',
        'fingerprint',
        'fcm_token',
        'platform',
        'browser',
        'is_trusted',
        'last_used_at',
    ];

    protected function casts(): array
    {
        return [
            'is_trusted' => 'boolean',
            'last_used_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}