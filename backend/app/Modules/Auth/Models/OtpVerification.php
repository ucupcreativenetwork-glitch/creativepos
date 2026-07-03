<?php

namespace App\Modules\Auth\Models;

use App\Modules\Auth\Enums\OtpChannel;
use App\Modules\Auth\Enums\OtpPurpose;
use Illuminate\Database\Eloquent\Model;

class OtpVerification extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'identifier',
        'channel',
        'code_hash',
        'purpose',
        'attempts',
        'max_attempts',
        'expires_at',
        'verified_at',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'channel' => OtpChannel::class,
            'purpose' => OtpPurpose::class,
            'expires_at' => 'datetime',
            'verified_at' => 'datetime',
            'created_at' => 'datetime',
        ];
    }

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    public function isVerified(): bool
    {
        return $this->verified_at !== null;
    }

    public function hasExceededAttempts(): bool
    {
        return $this->attempts >= $this->max_attempts;
    }
}