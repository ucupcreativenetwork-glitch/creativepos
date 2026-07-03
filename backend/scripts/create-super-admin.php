<?php

/**
 * Buat atau perbarui akun Super Admin (akses /platform).
 *
 * Usage (di server Docker):
 *   docker compose -f docker-compose.client.yml exec -T backend \
 *     php scripts/create-super-admin.php admin@creativepos.local "PasswordKuat123!"
 */

use App\Models\Role;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$email = strtolower(trim($argv[1] ?? ''));
$password = $argv[2] ?? '';

if ($email === '' || ! filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "Usage: php scripts/create-super-admin.php <email> <password>\n");
    exit(1);
}

if (strlen($password) < 8) {
    fwrite(STDERR, "Password minimal 8 karakter.\n");
    exit(1);
}

$user = User::query()
    ->where('email', $email)
    ->whereNull('tenant_id')
    ->where('is_super_admin', true)
    ->first();

if ($user === null) {
    $user = User::query()->create([
        'tenant_id' => null,
        'name' => 'Super Admin',
        'email' => $email,
        'password' => Hash::make($password),
        'is_super_admin' => true,
        'status' => 'active',
        'email_verified_at' => now(),
    ]);
    $action = 'dibuat';
} else {
    $user->update([
        'password' => Hash::make($password),
        'status' => 'active',
    ]);
    $action = 'diperbarui';
}

$role = Role::query()
    ->where('name', 'super-admin')
    ->whereNull('tenant_id')
    ->first();

if ($role !== null) {
    $user->syncRoles([$role]);
}

echo "Super Admin {$action}.\n";
echo "Email   : {$email}\n";
echo "Login   : /login lalu buka /platform\n";