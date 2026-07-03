<?php

namespace App\Modules\Auth\Enums;

enum OtpChannel: string
{
    case Email = 'email';
    case Whatsapp = 'whatsapp';
    case Sms = 'sms';
}