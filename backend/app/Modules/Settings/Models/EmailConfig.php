<?php

namespace App\Modules\Settings\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;

class EmailConfig extends Model
{
    use BelongsToTenant;

    protected $fillable = [
        'tenant_id',
        'mailer',
        'host',
        'port',
        'encryption',
        'username',
        'password',
        'from_address',
        'from_name',
        'is_active',
        'send_welcome_email',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'send_welcome_email' => 'boolean',
            'port' => 'integer',
        ];
    }

    protected function password(): Attribute
    {
        return Attribute::make(
            get: fn (?string $value) => $value ? Crypt::decryptString($value) : null,
            set: fn (?string $value) => $value ? Crypt::encryptString($value) : null,
        );
    }
}