<?php

namespace App\Modules\Notification\Enums;

enum WhatsappProvider: string
{
    case Fonnte = 'fonnte';
    case Wablas = 'wablas';
    case Meta = 'meta';

    public function defaultApiUrl(): string
    {
        return match ($this) {
            self::Fonnte => 'https://api.fonnte.com/send',
            self::Wablas => '',
            self::Meta => '',
        };
    }
}