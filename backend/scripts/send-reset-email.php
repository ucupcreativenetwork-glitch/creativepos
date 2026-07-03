<?php

use App\Modules\Auth\Services\AuthService;
use Illuminate\Support\Facades\DB;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = $argv[1] ?? 'admin@creativenetwork.my.id';

DB::table('password_reset_tokens')->where('email', $email)->delete();

try {
    app(AuthService::class)->sendPasswordResetLink($email);
    echo "Reset link sent to {$email}\n";
} catch (Throwable $e) {
    fwrite(STDERR, $e->getMessage()."\n");
    exit(1);
}