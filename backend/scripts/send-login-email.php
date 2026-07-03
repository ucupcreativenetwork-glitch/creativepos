<?php

use App\Models\User;
use App\Modules\Notification\Notifications\PasswordResetConfirmationNotification;
use App\Modules\Notification\Services\MailConfigService;
use App\Modules\Platform\Models\Tenant;
use App\Shared\Support\FrontendUrl;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = $argv[1] ?? 'admin@creativenetwork.my.id';
$user = User::query()->where('email', $email)->firstOrFail();

if ($user->tenant_id) {
    set_tenant(Tenant::query()->find($user->tenant_id));
}

app(MailConfigService::class)->applyForTenant($user->tenant_id);
$user->notify(new PasswordResetConfirmationNotification);

echo "Email konfirmasi dikirim ke {$email}\n";
echo "Tombol login mengarah ke: ".FrontendUrl::login()."\n";