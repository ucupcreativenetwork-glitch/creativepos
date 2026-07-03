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

function api(string $method, string $path, ?array $body, string $token, int $tenantId): array
{
    global $base;
    $ch = curl_init($base.$path);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Accept: application/json',
            'Content-Type: application/json',
            'Authorization: Bearer '.$token,
            'X-Tenant-ID: '.$tenantId,
        ],
        CURLOPT_POSTFIELDS => $body ? json_encode($body) : null,
    ]);
    $response = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [$code, $response];
}

echo 'Tenant: '.$tenantId.PHP_EOL;

[$code, $body] = api('GET', '/inventory/stocks/warehouses', null, $token, $tenantId);
echo "Warehouses HTTP $code\n$body\n\n";

[$code, $body] = api('GET', '/inventory/products?per_page=1', null, $token, $tenantId);
$products = json_decode($body, true);
$product = $products['data'][0] ?? null;
echo 'Product: '.($product['name'] ?? 'none').' id='.($product['id'] ?? '-').' stock='.($product['total_stock'] ?? '-').PHP_EOL;

$warehouses = json_decode(api('GET', '/inventory/stocks/warehouses', null, $token, $tenantId)[1], true);
$warehouseId = $warehouses['data'][0]['id'] ?? 1;
$productId = $product['id'] ?? 3;

foreach ([
    ['POST', '/inventory/stocks/in', ['product_id' => $productId, 'warehouse_id' => $warehouseId, 'quantity' => 1, 'notes' => 'test in']],
    ['POST', '/inventory/stocks/out', ['product_id' => $productId, 'warehouse_id' => $warehouseId, 'quantity' => 1, 'notes' => 'test out']],
    ['POST', '/inventory/stocks/adjustment', ['product_id' => $productId, 'warehouse_id' => $warehouseId, 'quantity' => 10, 'notes' => 'test adj']],
    ['POST', '/inventory/stocks/adjustment', ['product_id' => $productId, 'warehouse_id' => $warehouseId, 'quantity' => 10, 'reason' => 'wrong field']],
    ['POST', '/inventory/stocks/in', ['product_id' => $productId, 'warehouse_id' => 1, 'quantity' => 1, 'notes' => 'wrong warehouse']],
] as [$method, $path, $payload]) {
    [$code, $resp] = api($method, $path, $payload, $token, $tenantId);
    $json = json_decode($resp, true);
    echo "$path => HTTP $code: ".($json['message'] ?? substr($resp, 0, 120)).PHP_EOL;
}