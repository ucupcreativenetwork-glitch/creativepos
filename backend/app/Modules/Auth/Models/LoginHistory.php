<?php

namespace App\Modules\Auth\Models;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LoginHistory extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id',
        'tenant_id',
        'ip_address',
        'user_agent',
        'device_fingerprint',
        'device_name',
        'location',
        'is_successful',
        'failure_reason',
        'logged_in_at',
        'logged_out_at',
    ];

    protected function casts(): array
    {
        return [
            'is_successful' => 'boolean',
            'logged_in_at' => 'datetime',
            'logged_out_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}