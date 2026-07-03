<?php

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Password;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = $argv[1] ?? 'admin@creativenetwork.my.id';
$user = User::query()->where('email', $email)->first();
if ($user === null) {
    fwrite(STDERR, "User not found\n");
    exit(1);
}

DB::table('password_reset_tokens')->where('email', $email)->delete();
$token = Password::broker()->createToken($user);
$frontend = rtrim((string) config('creativepos.payment.frontend_url'), '/');
$link = $frontend.'/reset-password/'.$token.'?email='.urlencode($email);

echo $link."\n";