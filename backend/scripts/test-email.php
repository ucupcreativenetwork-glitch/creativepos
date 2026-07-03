<?php

use App\Modules\Notification\Services\MailConfigService;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$recipient = $argv[1] ?? 'admin@creativenetwork.my.id';
$tenantId = (int) ($argv[2] ?? 3);

$result = app(MailConfigService::class)->sendTestEmail($recipient, $tenantId);

echo json_encode($result, JSON_PRETTY_PRINT)."\n";