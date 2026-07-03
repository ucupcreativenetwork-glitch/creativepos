<?php

use App\Models\User;
use Illuminate\Support\Facades\Hash;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = $argv[1] ?? 'admin@creativenetwork.my.id';
$password = $argv[2] ?? 'CreativePOS123';

$user = User::query()->where('email', $email)->first();
if ($user === null) {
    fwrite(STDERR, "User not found: {$email}\n");
    exit(1);
}

$user->forceFill(['password' => Hash::make($password)])->save();

echo "Password updated for {$email}\n";