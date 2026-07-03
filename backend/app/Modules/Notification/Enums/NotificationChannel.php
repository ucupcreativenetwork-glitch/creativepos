<?php

namespace App\Modules\Notification\Enums;

enum NotificationChannel: string
{
    case Email = 'email';
    case Whatsapp = 'whatsapp';
    case Push = 'push';
    case InApp = 'in_app';
}