<?php

namespace App\Modules\Auth\Enums;

enum TwoFactorMethod: string
{
    case Totp = 'totp';
    case Whatsapp = 'whatsapp';
    case Email = 'email';
}