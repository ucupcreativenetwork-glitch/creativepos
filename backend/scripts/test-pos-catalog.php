<?php

$base = 'http://10.110.1.15:8000/api/v1';

$ch = curl_init("$base/auth/login");
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Accept: application/json', 'Content-Type: application/json'],
    CURLOPT_POSTFIELDS => json_encode([
        'email' => 'admin@creativenetwork.my.id',
        'password' => 'CreativePOS123',
    ]),
]);
$login = json_decode(curl_exec($ch), true);
curl_close($ch);

$token = $login['data']['token'] ?? null;
$tenantId = $login['data']['tenant']['id'] ?? null;

echo 'Login: '.($token ? 'OK' : 'FAIL').PHP_EOL;
echo 'Tenant: '.$tenantId.PHP_EOL;

foreach ([
    '/settings/outlets',
    '/pos/catalog/products',
    '/pos/catalog/categories',
    '/pos/catalog/payment-methods',
] as $path) {
    $ch = curl_init($base.$path);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Accept: application/json',
            'Authorization: Bearer '.$token,
            'X-Tenant-ID: '.$tenantId,
        ],
    ]);
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    $json = json_decode($body, true);
    $count = is_array($json['data'] ?? null) ? count($json['data']) : 'n/a';
    echo "$path => HTTP $code, items: $count".PHP_EOL;
    if ($code >= 400) {
        echo substr($body, 0, 400).PHP_EOL;
    } elseif ($path === '/settings/outlets' || $path === '/pos/catalog/products') {
        echo json_encode($json['data'][0] ?? null, JSON_PRETTY_PRINT).PHP_EOL;
    }
}