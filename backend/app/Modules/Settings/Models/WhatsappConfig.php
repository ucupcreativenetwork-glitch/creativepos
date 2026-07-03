<?php

namespace App\Modules\Settings\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;

class WhatsappConfig extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'provider',
        'api_url',
        'phone_number',
        'api_token',
        'webhook_secret',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    protected function apiToken(): Attribute
    {
        return Attribute::make(
            get: fn (?string $value) => $value ? Crypt::decryptString($value) : null,
            set: fn (?string $value) => $value ? Crypt::encryptString($value) : null,
        );
    }
}