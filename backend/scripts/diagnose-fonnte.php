<?php

use App\Modules\Platform\Models\Tenant;
use App\Modules\Settings\Models\WhatsappConfig;
use Illuminate\Support\Facades\Http;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$tenantId = (int) ($argv[1] ?? 3);
$target = $argv[2] ?? '087882521602';

$tenant = Tenant::query()->find($tenantId);
if ($tenant === null) {
    fwrite(STDERR, "Tenant not found\n");
    exit(1);
}

set_tenant($tenant);

$config = WhatsappConfig::query()->withoutGlobalScopes()->where('tenant_id', $tenantId)->first();
if ($config === null || blank($config->api_token)) {
    fwrite(STDERR, "WhatsApp config/token not found for tenant {$tenantId}\n");
    exit(1);
}

$token = $config->api_token;
$client = Http::timeout(30);
if (app()->environment('local')) {
    $client = $client->withoutVerifying();
}

echo "=== Diagnosa Fonnte — Tenant {$tenantId} ===\n";
echo "Sender config: {$config->phone_number}\n";
echo "Provider: {$config->provider}\n";
echo "Active: ".($config->is_active ? 'yes' : 'no')."\n";
echo "Target test: {$target}\n\n";

$endpoints = [
    'device' => 'https://api.fonnte.com/device',
    'validate' => 'https://api.fonnte.com/validate',
    'qr' => 'https://api.fonnte.com/qr',
];

echo "--- POST device profile ---\n";
try {
    $response = $client->withHeaders(['Authorization' => $token])->post('https://api.fonnte.com/device');
    echo "HTTP: {$response->status()}\n";
    $body = $response->json();
    echo json_encode($body, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)."\n";
    $status = is_array($body) ? ($body['device_status'] ?? 'unknown') : 'unknown';
    echo ">>> Device status: {$status}\n\n";
} catch (Throwable $e) {
    echo "ERROR: {$e->getMessage()}\n\n";
}

$targets = [
    'format_08' => preg_replace('/\D+/', '', $target),
    'format_62' => '62'.ltrim(preg_replace('/\D+/', '', $target), '0'),
];

if (str_starts_with($targets['format_08'], '62')) {
    $targets['format_08'] = '0'.substr($targets['format_08'], 2);
}
if (! str_starts_with($targets['format_08'], '0')) {
    $targets['format_08'] = '0'.$targets['format_08'];
}

foreach ($targets as $label => $formattedTarget) {
    echo "--- SEND test ({$label}: {$formattedTarget}) ---\n";
    try {
        $response = $client
            ->withHeaders(['Authorization' => $token])
            ->asForm()
            ->post('https://api.fonnte.com/send', [
                'target' => $formattedTarget,
                'message' => '[CreativePOS] Uji diagnosa '.now()->format('H:i:s').' — jika Anda terima pesan ini, Fonnte sudah jalan.',
                'countryCode' => '62',
                'connectOnly' => 'true',
            ]);
        echo "HTTP: {$response->status()}\n";
        echo "Body: {$response->body()}\n";
        echo json_encode($response->json(), JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)."\n\n";
    } catch (Throwable $e) {
        echo "ERROR: {$e->getMessage()}\n\n";
    }
}