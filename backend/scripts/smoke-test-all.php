<?php

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$base = rtrim(getenv('SMOKE_BASE_URL') ?: 'http://127.0.0.1:8000/api/v1', '/');
$email = $argv[1] ?? 'admin@creativenetwork.my.id';
$password = $argv[2] ?? 'CreativePOS123';

$results = [];
$token = null;
$tenantId = 3;

function smoke(array &$results, string $name, bool $ok, string $detail): void
{
    $results[] = compact('name', 'ok', 'detail');
    echo '['.($ok ? 'OK' : 'FAIL')."] {$name}: {$detail}\n";
}

function request(string $method, string $url, ?array $body = null, ?string $token = null, array $headers = []): array
{
    $ch = curl_init($url);
    $httpHeaders = array_merge(['Accept: application/json', 'Content-Type: application/json'], $headers);
    if ($token) {
        $httpHeaders[] = 'Authorization: Bearer '.$token;
    }

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_HTTPHEADER => $httpHeaders,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_SSL_VERIFYPEER => false,
    ]);

    if ($body !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }

    $response = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [
        'code' => $code,
        'json' => json_decode((string) $response, true),
        'raw' => (string) $response,
    ];
}

echo "=== Smoke Test CreativePOS ===\nBase: {$base}\n\n";

// AUTH
$r = request('POST', "{$base}/auth/login", [
    'email' => $email,
    'password' => $password,
    'device_name' => 'Smoke Test',
]);
$token = $r['json']['data']['token'] ?? null;
$tenantId = $r['json']['data']['tenant']['id'] ?? $tenantId;
smoke($results, 'Auth: Login', $r['code'] === 200 && filled($token), $r['code'].' — '.($r['json']['message'] ?? 'no message'));

$r = request('GET', "{$base}/auth/me", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Auth: Me', $r['code'] === 200 && ($r['json']['success'] ?? false), 'HTTP '.$r['code']);

// INVENTORY
$r = request('GET', "{$base}/inventory/categories?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Inventory: Categories', $r['code'] === 200, 'HTTP '.$r['code']);

$r = request('GET', "{$base}/inventory/products?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Inventory: Products', $r['code'] === 200, 'HTTP '.$r['code']);

// POS
$r = request('GET', "{$base}/pos/shifts/current", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'POS: Current Shift', in_array($r['code'], [200, 404], true), 'HTTP '.$r['code']);

$r = request('GET', "{$base}/pos/transactions?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'POS: Transactions', $r['code'] === 200, 'HTTP '.$r['code']);

// LOYALTY
$r = request('GET', "{$base}/members?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Loyalty: Members', $r['code'] === 200, 'HTTP '.$r['code']);

// ORDERS (403 = paket tidak include fitur order — bukan error)
$r = request('GET', "{$base}/orders?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
$orderOk = $r['code'] === 200 || (
    $r['code'] === 403 && str_contains((string) ($r['json']['message'] ?? ''), 'subscription plan')
);
smoke($results, 'Orders: List', $orderOk, 'HTTP '.$r['code'].' — '.($r['json']['message'] ?? ''));

// REPORTS
$r = request('GET', "{$base}/reports/sales", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Reports: Sales', $r['code'] === 200, 'HTTP '.$r['code']);

$r = request('GET', "{$base}/reports/exports?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Reports: Exports (paginator fix)', $r['code'] === 200, 'HTTP '.$r['code']);

// BILLING
$r = request('GET', "{$base}/billing/invoices?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Billing: Invoices (paginator fix)', $r['code'] === 200, 'HTTP '.$r['code']);

$r = request('GET', "{$base}/billing/subscription", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Billing: Subscription', $r['code'] === 200, 'HTTP '.$r['code']);

// SETTINGS
$r = request('GET', "{$base}/settings/tenant", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Settings: Tenant', $r['code'] === 200, 'HTTP '.$r['code']);

$r = request('GET', "{$base}/settings/integrations", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Settings: Integrations', $r['code'] === 200, 'HTTP '.$r['code']);

// NOTIFICATIONS
$r = request('GET', "{$base}/notifications?per_page=5", null, $token, ['X-Tenant-ID: '.$tenantId]);
smoke($results, 'Notifications: List', $r['code'] === 200, 'HTTP '.$r['code']);

// OTP send (expires_in fix)
$r = request('POST', "{$base}/auth/otp/email", [
    'email' => $email,
    'purpose' => 'login',
]);
$expiresIn = $r['json']['data']['expires_in'] ?? null;
smoke($results, 'Auth: OTP Email', $r['code'] === 200, 'HTTP '.$r['code'].' expires_in='.json_encode($expiresIn));

// FRONTEND URL
$loginUrl = App\Shared\Support\FrontendUrl::login();
smoke($results, 'Config: FrontendUrl', str_contains($loginUrl, '10.110.1.15'), $loginUrl);

$passed = count(array_filter($results, fn ($r) => $r['ok']));
$total = count($results);
echo "\n=== Ringkasan: {$passed}/{$total} lulus ===\n";

exit($passed < $total ? 1 : 0);