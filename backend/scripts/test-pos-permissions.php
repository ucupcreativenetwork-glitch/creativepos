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

$data = $login['data'] ?? [];
echo 'Permissions: '.implode(', ', $data['permissions'] ?? []).PHP_EOL;
echo 'Has pos.create: '.(in_array('pos.create', $data['permissions'] ?? [], true) ? 'yes' : 'no').PHP_EOL;
echo 'Has tenant.settings.view: '.(in_array('tenant.settings.view', $data['permissions'] ?? [], true) ? 'yes' : 'no').PHP_EOL;