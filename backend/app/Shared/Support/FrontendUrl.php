<?php

namespace App\Shared\Support;

class FrontendUrl
{
    public static function base(): string
    {
        $url = config('creativepos.payment.frontend_url')
            ?: config('app.frontend_url')
            ?: config('app.url');

        return rtrim((string) $url, '/');
    }

    public static function path(string $path = ''): string
    {
        $path = ltrim($path, '/');

        return $path === '' ? self::base() : self::base().'/'.$path;
    }

    public static function login(): string
    {
        return self::path('login');
    }

    public static function resetPassword(string $token, string $email): string
    {
        return self::path('reset-password/'.$token).'?email='.urlencode($email);
    }
}