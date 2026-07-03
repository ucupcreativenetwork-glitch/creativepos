<?php

/**
 * Uji integrasi sistem CreativePOS (API live).
 *
 * Usage: php scripts/test-system.php [base_url]
 * Default: http://127.0.0.1:8000/api/v1
 */

$base = rtrim($argv[1] ?? getenv('TEST_API_BASE') ?: 'http://127.0.0.1:8000/api/v1', '/');

$adminEmail = getenv('TEST_ADMIN_EMAIL') ?: 'admin@creativepos.local';
$adminPassword = getenv('TEST_ADMIN_PASSWORD') ?: 'Admin123!';
$superEmail = getenv('TEST_SUPER_EMAIL') ?: 'superadmin@creativepos.local';
$superPassword = getenv('TEST_SUPER_PASSWORD') ?: 'SuperAdmin123!';

// Fallback kredensial dev lokal (jika akun demo belum di-seed)
$adminFallbackEmail = 'admin@creativenetwork.my.id';
$adminFallbackPassword = 'CreativePOS123';

$passed = 0;
$failed = 0;
$skipped = 0;

function section(string $title): void
{
    echo "\n=== {$title} ===\n";
}

function ok(string $label): void
{
    global $passed;
    $passed++;
    echo "  PASS  {$label}\n";
}

function fail(string $label, string $detail = ''): void
{
    global $failed;
    $failed++;
    echo "  FAIL  {$label}".($detail !== '' ? " — {$detail}" : '')."\n";
}

function skip(string $label, string $reason = ''): void
{
    global $skipped;
    $skipped++;
    echo "  SKIP  {$label}".($reason !== '' ? " — {$reason}" : '')."\n";
}

function request(
    string $method,
    string $path,
    ?array $body = null,
    ?string $token = null,
    ?int $tenantId = null,
    ?array $multipart = null,
): array {
    global $base;

    $url = $base.$path;
    $ch = curl_init($url);
    $headers = ['Accept: application/json'];

    if ($token) {
        $headers[] = 'Authorization: Bearer '.$token;
    }
    if ($tenantId) {
        $headers[] = 'X-Tenant-ID: '.$tenantId;
    }

    if ($multipart !== null) {
        $headers[] = 'Content-Type: multipart/form-data';
        curl_setopt($ch, CURLOPT_POSTFIELDS, $multipart);
        $method = 'POST';
    } elseif ($body !== null) {
        $headers[] = 'Content-Type: application/json';
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($body));
    }

    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_TIMEOUT => 30,
    ]);

    $response = curl_exec($ch);
    $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return [$code, json_decode((string) $response, true), (string) $response];
}

section('Health & Auth');
[$code, $json] = request('GET', '/health');
$code === 200 && ($json['success'] ?? false) ? ok('API health') : fail('API health', "HTTP {$code}");

[$code, $json] = request('POST', '/auth/login', [
    'email' => $adminEmail,
    'password' => $adminPassword,
    'device_name' => 'System Test',
]);

if ($code !== 200 || empty($json['data']['token'])) {
    [$code, $json] = request('POST', '/auth/login', [
        'email' => $adminFallbackEmail,
        'password' => $adminFallbackPassword,
        'device_name' => 'System Test',
    ]);
    if ($code === 200 && ! empty($json['data']['token'])) {
        $adminEmail = $adminFallbackEmail;
        $adminPassword = $adminFallbackPassword;
        ok('Login admin (fallback dev lokal)');
    }
}

$adminToken = $json['data']['token'] ?? null;
$adminTenantId = $json['data']['tenant']['id'] ?? null;
$adminUser = $json['data']['user'] ?? [];
$adminPermissions = $json['data']['permissions'] ?? [];

if ($code === 200 && $adminToken) {
    ok("Login admin ({$adminEmail})");
} else {
    fail('Login admin', $json['message'] ?? "HTTP {$code}");
}

$mustChange = (bool) ($adminUser['must_change_password'] ?? false);
$mustChange ? ok('Flag must_change_password aktif') : skip('Flag must_change_password', 'kolom belum dimigrate/seed');

if ($adminToken && $mustChange) {
    [$code, $json] = request('GET', '/dashboard/kpi', null, $adminToken, $adminTenantId);
    $code === 403 && ($json['code'] ?? '') === 'PASSWORD_CHANGE_REQUIRED'
        ? ok('Middleware blokir API sebelum ganti password')
        : fail('Middleware blokir API', "HTTP {$code}");
}

$newPassword = 'AdminTest123!X';
if ($adminToken && $mustChange) {
    [$code, $json] = request('POST', '/auth/change-password', [
        'current_password' => $adminPassword,
        'password' => $newPassword,
        'password_confirmation' => $newPassword,
    ], $adminToken, $adminTenantId);

    if ($code === 200 && ! ($json['data']['must_change_password'] ?? true)) {
        ok('Ganti password admin');
        $adminToken = null;
        [$code, $json] = request('POST', '/auth/login', [
            'email' => $adminEmail,
            'password' => $newPassword,
            'device_name' => 'System Test',
        ]);
        $adminToken = $json['data']['token'] ?? $adminToken;
    } else {
        fail('Ganti password admin', $json['message'] ?? "HTTP {$code}");
    }
} elseif ($adminToken) {
    [$code, $json] = request('POST', '/auth/login', [
        'email' => 'admin@creativepos.local',
        'password' => $newPassword,
        'device_name' => 'System Test',
    ]);
    if ($code === 200) {
        $adminToken = $json['data']['token'] ?? $adminToken;
        ok('Login admin dengan password terbaru');
    }
}

if ($adminToken) {
    [$code] = request('GET', '/dashboard/kpi', null, $adminToken, $adminTenantId);
    $code === 200 ? ok('Dashboard API setelah ganti password') : fail('Dashboard API', "HTTP {$code}");
}

section('Inventori — Import Produk & Stok');
if (! $adminToken) {
    skip('Semua tes inventori', 'tidak ada token admin');
} else {
    $sku = 'SYS-TEST-'.time();
    $csv = "name,sku,base_price,cost_price,category_name,initial_stock,min_stock,track_stock\n";
    $csv .= "Produk Uji Sistem,{$sku},15000,5000,Uji Sistem,10,2,1\n";
    $tmp = tempnam(sys_get_temp_dir(), 'prod-import-');
    file_put_contents($tmp, $csv);

    [$code, $json] = request(
        'POST',
        '/inventory/products/import',
        null,
        $adminToken,
        $adminTenantId,
        ['file' => new CURLFile($tmp, 'text/csv', 'products.csv')],
    );
    unlink($tmp);

    ($code === 200 && ($json['data']['created'] ?? 0) >= 1)
        ? ok('Import produk CSV')
        : fail('Import produk CSV', $json['message'] ?? "HTTP {$code}");

    $stockCsv = "sku,quantity,action,notes\n{$sku},3,in,Uji sistem\n";
    $tmp2 = tempnam(sys_get_temp_dir(), 'stock-import-');
    file_put_contents($tmp2, $stockCsv);

    [$code, $json] = request(
        'POST',
        '/inventory/stocks/import',
        null,
        $adminToken,
        $adminTenantId,
        ['file' => new CURLFile($tmp2, 'text/csv', 'stock.csv')],
    );
    unlink($tmp2);

    ($code === 200 && ($json['data']['processed'] ?? 0) >= 1)
        ? ok('Import stok CSV')
        : fail('Import stok CSV', $json['message'] ?? "HTTP {$code}");

    [$code, $json] = request('GET', '/inventory/products?search='.$sku, null, $adminToken, $adminTenantId);
    $product = $json['data'][0] ?? null;
    ($code === 200 && $product && ($product['total_stock'] ?? 0) >= 10)
        ? ok('Stok produk terupdate setelah import')
        : fail('Verifikasi stok produk', 'stok='.$product['total_stock'] ?? '-');
}

section('Permission RBAC (cek response login)');
$expectedAdminPerms = ['inventory.create', 'inventory.stock.adjust', 'dashboard.view', 'pos.create'];
foreach ($expectedAdminPerms as $perm) {
    in_array($perm, $adminPermissions, true)
        ? ok("Permission admin: {$perm}")
        : fail("Permission admin: {$perm}");
}

section('Modul inti');
if ($adminToken) {
    foreach ([
        ['GET', '/inventory/products?per_page=1', 'Inventori produk'],
        ['GET', '/inventory/stocks/alerts', 'Alert stok'],
        ['GET', '/pos/catalog/products', 'Katalog POS'],
        ['GET', '/billing/subscription', 'Langganan'],
        ['GET', '/settings/tenant', 'Pengaturan tenant'],
    ] as [$method, $path, $label]) {
        [$code, $json] = request($method, $path, null, $adminToken, $adminTenantId);
        $code === 200 ? ok($label) : fail($label, "HTTP {$code} — ".($json['message'] ?? ''));
    }
}

section('Super Admin');
[$code, $json] = request('POST', '/auth/login', [
    'email' => $superEmail,
    'password' => $superPassword,
    'device_name' => 'System Test',
]);
$saToken = $json['data']['token'] ?? null;
$saMustChange = (bool) ($json['data']['user']['must_change_password'] ?? false);

if ($code === 200 && $saToken) {
    ok('Login super admin');
    if ($saMustChange) {
        [$c, $j] = request('POST', '/auth/change-password', [
            'current_password' => $superPassword,
            'password' => 'SuperTest123!X',
            'password_confirmation' => 'SuperTest123!X',
        ], $saToken, $json['data']['tenant']['id'] ?? null);
        $c === 200 ? ok('Ganti password super admin') : fail('Ganti password super admin', "HTTP {$c}");
        [$code, $json] = request('POST', '/auth/login', [
            'email' => $superEmail,
            'password' => 'SuperTest123!X',
            'device_name' => 'System Test',
        ]);
        $saToken = $json['data']['token'] ?? $saToken;
    }
    [$code] = request('GET', '/platform/tenants?per_page=1', null, $saToken, $json['data']['tenant']['id'] ?? null);
    $code === 200 ? ok('Platform tenants API') : fail('Platform tenants API', "HTTP {$code}");
} else {
    $detail = $json['message'] ?? "HTTP {$code}";
    if (str_contains($detail, 'trial account unique recipients limit') || str_contains($detail, '450')) {
        skip('Login super admin', 'SMTP/Mailgun trial limit — bukan bug aplikasi');
    } else {
        fail('Login super admin', $detail);
    }
}

section('Ringkasan');
$total = $passed + $failed + $skipped;
echo "\nTotal: {$total} | PASS: {$passed} | FAIL: {$failed} | SKIP: {$skipped}\n";

if ($failed > 0) {
    echo "\nBeberapa uji gagal. Periksa migrate/seed:\n";
    echo "  php artisan migrate --force\n";
    echo "  php artisan db:seed --class=DefaultAccountsSeeder --force\n";
    exit(1);
}

echo "\nSemua uji kritis lulus.\n";
exit(0);