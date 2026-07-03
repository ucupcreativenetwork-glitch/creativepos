<?php

use App\Modules\Settings\Models\WhatsappConfig;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$config = WhatsappConfig::query()->withoutGlobalScopes()->where('tenant_id', 3)->first();
$token = $config->api_token;
$target = $argv[1] ?? '087882521602';

$tests = [
    'curl_simple' => function () use ($token, $target): string {
        $ch = curl_init('https://api.fonnte.com/send');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => ['Authorization: '.$token],
            CURLOPT_POSTFIELDS => [
                'target' => $target,
                'message' => 'CreativePOS test '.date('H:i:s'),
                'countryCode' => '62',
            ],
            CURLOPT_SSL_VERIFYPEER => false,
        ]);
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        return "HTTP {$code}\n{$body}";
    },
    'validate' => function () use ($token, $target): string {
        $ch = curl_init('https://api.fonnte.com/validate');
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_HTTPHEADER => ['Authorization: '.$token],
            CURLOPT_POSTFIELDS => [
                'target' => $target,
                'countryCode' => '62',
            ],
            CURLOPT_SSL_VERIFYPEER => false,
        ]);
        $body = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        return "HTTP {$code}\n{$body}";
    },
];

foreach ($tests as $name => $fn) {
    echo "=== {$name} ===\n";
    echo $fn()."\n\n";
}

$messageId = $argv[2] ?? null;
if ($messageId) {
    $ch = curl_init('https://api.fonnte.com/status');
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_HTTPHEADER => ['Authorization: '.$token],
        CURLOPT_POSTFIELDS => ['id' => $messageId],
        CURLOPT_SSL_VERIFYPEER => false,
    ]);
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    echo "=== status {$messageId} ===\nHTTP {$code}\n{$body}\n";
}