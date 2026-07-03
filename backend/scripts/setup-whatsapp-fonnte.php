<?php

use App\Modules\Notification\Services\WhatsappService;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Settings\Models\WhatsappConfig;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$tenantId = (int) ($argv[1] ?? 3);
$token = $argv[2] ?? null;
$senderPhone = $argv[3] ?? '6287882521602';
$testPhone = $argv[4] ?? '087882521602';

if (blank($token)) {
    fwrite(STDERR, "Usage: php scripts/setup-whatsapp-fonnte.php [tenant_id] [token] [sender_phone] [test_phone]\n");
    exit(1);
}

$tenant = Tenant::query()->find($tenantId);
if ($tenant === null) {
    fwrite(STDERR, "Tenant {$tenantId} not found\n");
    exit(1);
}

set_tenant($tenant);

$phoneNumber = preg_replace('/\D+/', '', $senderPhone);
if (str_starts_with($phoneNumber, '62')) {
    $phoneNumber = '0'.substr($phoneNumber, 2);
}

$config = WhatsappConfig::query()->updateOrCreate(
    ['tenant_id' => $tenantId],
    [
        'provider' => 'fonnte',
        'api_url' => 'https://api.fonnte.com/send',
        'phone_number' => $phoneNumber,
        'api_token' => $token,
        'is_active' => true,
    ],
);

echo "WhatsApp Fonnte configured for tenant {$tenantId} ({$tenant->name})\n";
echo "Sender: {$config->phone_number} | Active: ".($config->is_active ? 'yes' : 'no')."\n\n";

$message = '*CreativePOS — Uji WhatsApp Fonnte*'."\n\n"
    .'Integrasi WhatsApp berhasil dikonfigurasi. Notifikasi login dan 2FA akan dikirim ke nomor terdaftar.';

$result = app(WhatsappService::class)->send($testPhone, $message, $tenantId);

echo json_encode($result, JSON_PRETTY_PRINT)."\n";

if (! ($result['success'] ?? false)) {
    exit(1);
}