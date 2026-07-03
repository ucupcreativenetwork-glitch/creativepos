<?php

use App\Models\User;
use App\Modules\Auth\Enums\OtpChannel;
use App\Modules\Auth\Enums\OtpPurpose;
use App\Modules\Auth\Events\UserLoggedIn;
use App\Modules\Auth\Jobs\SendOtpJob;
use App\Modules\Auth\Services\AuthService;
use App\Modules\Notification\Listeners\SendLoginNotification;
use App\Modules\Notification\Listeners\SendPasswordResetConfirmation;
use App\Modules\Notification\Notifications\LoginNotification;
use App\Modules\Notification\Notifications\PasswordResetConfirmationNotification;
use App\Modules\Notification\Notifications\ResetPasswordNotification;
use App\Modules\Notification\Services\MailConfigService;
use App\Modules\Notification\Services\WhatsappService;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Support\Facades\DB;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = $argv[1] ?? 'admin@creativenetwork.my.id';

$user = User::query()->where('email', $email)->first();

if ($user === null) {
    fwrite(STDERR, "User not found: {$email}\n");
    exit(1);
}

if ($user->tenant_id) {
    set_tenant(Tenant::query()->find($user->tenant_id));
}

$mailConfig = app(MailConfigService::class);
$mailConfig->applyForTenant($user->tenant_id);

$results = [];

function record(array &$results, string $name, bool $success, string $detail): void
{
    $results[] = [
        'test' => $name,
        'success' => $success,
        'detail' => $detail,
    ];
    $status = $success ? 'OK' : 'FAIL';
    echo "[{$status}] {$name}: {$detail}\n";
}

echo "=== Uji Notifikasi Auth — {$user->name} ({$user->email}) ===\n";
echo "Tenant ID: ".($user->tenant_id ?? 'n/a')." | Phone: ".($user->phone ?? 'n/a')."\n\n";

// 1. Email reset password (link)
try {
    DB::table('password_reset_tokens')->where('email', $email)->delete();
    app(AuthService::class)->sendPasswordResetLink($email);
    record($results, '1. Email link reset password', true, "Dikirim ke {$email}");
} catch (Throwable $e) {
    record($results, '1. Email link reset password', false, $e->getMessage());
}

// 2. Email konfirmasi reset password
try {
    $user->notify(new PasswordResetConfirmationNotification);
    record($results, '2. Email konfirmasi reset password', true, "Dikirim ke {$email}");
} catch (Throwable $e) {
    record($results, '2. Email konfirmasi reset password', false, $e->getMessage());
}

// 3. Email notifikasi login
try {
    $user->notify(new LoginNotification(
        ipAddress: '10.110.1.15',
        deviceName: 'Uji Coba Script',
    ));
    record($results, '3. Email notifikasi login', true, "Dikirim ke {$email}");
} catch (Throwable $e) {
    record($results, '3. Email notifikasi login', false, $e->getMessage());
}

// 4. WhatsApp notifikasi login
try {
    if (blank($user->phone)) {
        record($results, '4. WhatsApp notifikasi login', false, 'Nomor HP user kosong');
    } else {
        $notification = new LoginNotification(
            ipAddress: '10.110.1.15',
            deviceName: 'Uji Coba Script',
        );
        $waMessage = $notification->toWhatsapp($user);
        $waResult = app(WhatsappService::class)->send($user->phone, $waMessage, $user->tenant_id);

        record(
            $results,
            '4. WhatsApp notifikasi login',
            (bool) ($waResult['success'] ?? false),
            ($waResult['success'] ?? false)
                ? "Dikirim ke {$user->phone} (mode: ".($waResult['response']['mode'] ?? 'live').')'
                : ($waResult['error'] ?? 'Gagal mengirim WhatsApp'),
        );
    }
} catch (Throwable $e) {
    record($results, '4. WhatsApp notifikasi login', false, $e->getMessage());
}

// 5. Email kode 2FA
try {
    (new SendOtpJob(
        identifier: $email,
        code: '482910',
        channel: OtpChannel::Email,
        purpose: OtpPurpose::Login->value,
        tenantId: $user->tenant_id,
        userName: $user->name,
    ))->handle();
    record($results, '5. Email kode 2FA', true, "Dikirim ke {$email} (kode uji: 482910)");
} catch (Throwable $e) {
    record($results, '5. Email kode 2FA', false, $e->getMessage());
}

// 6. WhatsApp kode 2FA
try {
    if (blank($user->phone)) {
        record($results, '6. WhatsApp kode 2FA', false, 'Nomor HP user kosong');
    } else {
        (new SendOtpJob(
            identifier: $user->phone,
            code: '482910',
            channel: OtpChannel::Whatsapp,
            purpose: OtpPurpose::Login->value,
            tenantId: $user->tenant_id,
            userName: $user->name,
        ))->handle();
        record($results, '6. WhatsApp kode 2FA', true, "Dikirim ke {$user->phone} (kode uji: 482910)");
    }
} catch (Throwable $e) {
    record($results, '6. WhatsApp kode 2FA', false, $e->getMessage());
}

// 7. Listener event login (alur produksi)
try {
    (new SendLoginNotification)->handle(new UserLoggedIn($user, '10.110.1.15', 'Uji Event Listener'));
    record($results, '7. Listener UserLoggedIn (produksi)', true, 'Event diproses — email + WhatsApp');
} catch (Throwable $e) {
    record($results, '7. Listener UserLoggedIn (produksi)', false, $e->getMessage());
}

// 8. Listener konfirmasi reset (alur produksi)
try {
    (new SendPasswordResetConfirmation)->handle(new PasswordReset($user));
    record($results, '8. Listener PasswordReset (produksi)', true, 'Event diproses — email konfirmasi');
} catch (Throwable $e) {
    record($results, '8. Listener PasswordReset (produksi)', false, $e->getMessage());
}

$passed = count(array_filter($results, fn ($r) => $r['success']));
$total = count($results);

echo "\n=== Ringkasan: {$passed}/{$total} berhasil ===\n";

if ($passed < $total) {
    exit(1);
}