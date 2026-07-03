<?php

return [

    'name' => env('APP_NAME', 'CreativePOS'),

    'trial_days' => (int) env('CREATIVEPOS_TRIAL_DAYS', 14),

    'otp' => [
        'expiry_minutes' => (int) env('CREATIVEPOS_OTP_EXPIRY_MINUTES', 5),
        'max_attempts' => (int) env('CREATIVEPOS_OTP_MAX_ATTEMPTS', 5),
        'code_length' => 6,
    ],

    'login' => [
        'max_attempts' => (int) env('CREATIVEPOS_LOGIN_MAX_ATTEMPTS', 5),
        'lockout_minutes' => (int) env('CREATIVEPOS_LOGIN_LOCKOUT_MINUTES', 15),
    ],

    'token_expiry_days' => (int) env('CREATIVEPOS_TOKEN_EXPIRY_DAYS', 30),

    'tenant' => [
        'header' => env('TENANT_HEADER', 'X-Tenant-ID'),
        'domain_suffix' => env('TENANT_DOMAIN_SUFFIX', 'creativepos.app'),
    ],

    'packages' => [
        'default_slug' => 'starter',
    ],

    'whatsapp' => [
        'api_url' => env('WHATSAPP_API_URL'),
        'api_token' => env('WHATSAPP_API_TOKEN'),
    ],

    'notifications' => [
        'firebase' => [
            'server_key' => env('FIREBASE_SERVER_KEY'),
            'project_id' => env('FIREBASE_PROJECT_ID'),
        ],
    ],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    ],

    'payment' => [
        'frontend_url' => env('FRONTEND_URL', 'http://localhost:3000'),
        'midtrans' => [
            'server_key' => env('MIDTRANS_SERVER_KEY'),
            'client_key' => env('MIDTRANS_CLIENT_KEY'),
            'is_production' => (bool) env('MIDTRANS_IS_PRODUCTION', false),
        ],
        'xendit' => [
            'secret_key' => env('XENDIT_SECRET_KEY'),
            'webhook_token' => env('XENDIT_WEBHOOK_TOKEN'),
        ],
        'callback_urls' => [
            'midtrans' => env('APP_URL', 'http://localhost:8000').'/api/v1/webhooks/payment/midtrans',
            'xendit' => env('APP_URL', 'http://localhost:8000').'/api/v1/webhooks/payment/xendit',
        ],
    ],

    'system_roles' => [
        'super-admin',
        'owner',
        'manager',
        'supervisor',
        'cashier',
        'waiter',
        'kitchen',
        'driver',
        'customer-service',
        'customer',
    ],

];