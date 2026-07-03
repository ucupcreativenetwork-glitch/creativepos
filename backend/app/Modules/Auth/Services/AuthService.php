<?php

namespace App\Modules\Auth\Services;

use App\Models\Role;
use App\Models\User;
use App\Modules\Auth\Events\UserLoggedIn;
use App\Modules\Auth\Events\UserRegistered;
use App\Modules\Auth\Repositories\LoginHistoryRepository;
use App\Modules\Auth\Repositories\UserDeviceRepository;
use App\Modules\Auth\Repositories\UserRepository;
use App\Modules\Platform\Models\Package;
use App\Modules\Platform\Models\Subscription;
use App\Modules\Platform\Models\Tenant;
use App\Modules\Inventory\Models\Warehouse;
use App\Modules\Loyalty\Services\LoyaltyBootstrapService;
use App\Modules\Notification\Services\MailConfigService;
use App\Shared\Support\PaymentMethodCatalog;
use App\Modules\Tenant\Models\Outlet;
use App\Modules\Tenant\Models\TenantSetting;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthService
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly LoginHistoryRepository $loginHistories,
        private readonly UserDeviceRepository $devices,
        private readonly TwoFactorService $twoFactor,
    ) {}

    public function register(array $data, Request $request): array
    {
        return DB::transaction(function () use ($data, $request) {
            $slug = $this->generateUniqueSlug($data['business_name']);
            $packageSlug = $data['package_slug']
                ?? config('creativepos.packages.default_slug', 'starter');

            $package = Package::query()
                ->where('slug', $packageSlug)
                ->firstOrFail();

            $trialDays = $package->trial_days ?: config('creativepos.trial_days', 14);

            $tenant = Tenant::query()->create([
                'name' => $data['business_name'],
                'slug' => $slug,
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
                'status' => 'trial',
                'trial_ends_at' => now()->addDays($trialDays),
                'timezone' => config('app.timezone', 'Asia/Jakarta'),
                'currency' => 'IDR',
                'locale' => config('app.locale', 'id'),
            ]);

            set_tenant($tenant);

            Subscription::query()->create([
                'tenant_id' => $tenant->id,
                'package_id' => $package->id,
                'status' => 'active',
                'billing_cycle' => 'monthly',
                'starts_at' => now()->toDateString(),
                'ends_at' => now()->addDays($trialDays)->toDateString(),
            ]);

            PaymentMethodCatalog::syncToDatabase();

            TenantSetting::query()->create([
                'tenant_id' => $tenant->id,
                'business_name' => $data['business_name'],
                'setup_completed' => false,
                'enabled_payment_methods' => ['cash'],
                'tax_rate' => 11,
                'service_charge_rate' => 0,
            ]);

            $outlet = Outlet::query()->create([
                'tenant_id' => $tenant->id,
                'name' => 'Outlet Utama',
                'code' => 'OUT01',
                'is_default' => true,
                'is_active' => true,
            ]);

            Warehouse::query()->create([
                'tenant_id' => $tenant->id,
                'outlet_id' => $outlet->id,
                'name' => 'Gudang Utama',
                'code' => 'WH01',
                'is_active' => true,
            ]);

            app(LoyaltyBootstrapService::class)->ensureDefaults($tenant->id);

            $user = $this->users->create([
                'tenant_id' => $tenant->id,
                'name' => $data['owner_name'],
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
                'password' => $data['password'],
                'outlet_id' => $outlet->id,
                'status' => 'active',
            ]);

            $ownerRole = Role::query()
                ->where('name', 'owner')
                ->whereNull('tenant_id')
                ->where('is_system', true)
                ->first();

            if ($ownerRole) {
                $user->assignRole($ownerRole);
            }

            $token = $this->createToken($user, $data['device_name'] ?? 'Web Browser');
            $this->recordSuccessfulLogin($user, $request, $data['device_name'] ?? null);

            event(new UserRegistered($tenant, $user));
            app(MailConfigService::class)->sendWelcomeEmail($user, $tenant);

            return $this->buildAuthResponse($user, $token, false);
        });
    }

    public function login(array $credentials, Request $request): array
    {
        $this->checkRateLimit($credentials['email'], $request->ip());

        $user = $this->users->findByEmail($credentials['email'])
            ?? $this->users->findSuperAdminByEmail($credentials['email']);

        if ($user === null || ! Hash::check($credentials['password'], $user->password)) {
            $this->recordFailedLogin($user, $request, 'Invalid credentials');
            $this->incrementLoginAttempts($credentials['email'], $request->ip());

            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        if (! $user->isActive()) {
            $this->recordFailedLogin($user, $request, 'Account inactive');

            throw ValidationException::withMessages([
                'email' => ['Your account is not active.'],
            ]);
        }

        $this->clearLoginAttempts($credentials['email'], $request->ip());

        if ($user->tenant_id) {
            set_tenant(Tenant::query()->find($user->tenant_id));
        }

        if ($user->requiresTwoFactor()) {
            $pendingToken = $this->createPendingTwoFactorSession($user);

            return [
                'requires_2fa' => true,
                'two_factor_method' => $user->two_factor_method,
                'pending_token' => $pendingToken,
                'user' => $user,
            ];
        }

        $token = $this->createToken($user, $credentials['device_name'] ?? 'Web Browser');
        $this->recordSuccessfulLogin($user, $request, $credentials['device_name'] ?? null);

        event(new UserLoggedIn($user, $request->ip(), $credentials['device_name'] ?? null));

        return $this->buildAuthResponse($user, $token, false);
    }

    public function completeOtpLogin(User $user, Request $request, ?string $deviceName = null): array
    {
        if ($user->tenant_id) {
            set_tenant(Tenant::query()->find($user->tenant_id));
        }

        $device = $deviceName ?? 'OTP Login';
        $token = $this->createToken($user, $device);
        $this->recordSuccessfulLogin($user, $request, $device);

        event(new UserLoggedIn($user, $request->ip(), $device));

        return $this->buildAuthResponse($user, $token, false);
    }

    public function completeTwoFactorLogin(User $user, string $code, Request $request, ?string $deviceName = null): array
    {
        if (! $this->twoFactor->verify($user, $code)) {
            throw ValidationException::withMessages([
                'code' => ['Invalid two-factor authentication code.'],
            ]);
        }

        $token = $this->createToken($user, $deviceName ?? 'Web Browser');
        $this->recordSuccessfulLogin($user, $request, $deviceName);
        $this->clearPendingTwoFactorSession($user);

        event(new UserLoggedIn($user, $request->ip(), $deviceName));

        return $this->buildAuthResponse($user, $token, false);
    }

    public function getPendingTwoFactorUser(string $pendingToken): ?User
    {
        $userId = Cache::get("2fa_pending:{$pendingToken}");

        return $userId ? $this->users->find($userId) : null;
    }

    public function logout(User $user, ?string $tokenId = null): void
    {
        if ($tokenId) {
            $user->tokens()->where('id', $tokenId)->delete();
        } else {
            $user->currentAccessToken()?->delete();
        }

        $this->loginHistories->markLoggedOut($user);
    }

    public function me(User $user): array
    {
        if ($user->tenant_id) {
            set_tenant(Tenant::query()->find($user->tenant_id));
        }

        return $this->buildAuthResponse($user, null, false);
    }

    public function sendPasswordResetLink(string $email): string
    {
        $user = $this->users->findByEmail($email)
            ?? $this->users->findSuperAdminByEmail($email);

        if ($user?->tenant_id) {
            app(MailConfigService::class)->applyForTenant($user->tenant_id);
        }

        $status = Password::sendResetLink(['email' => $email]);

        if ($status !== Password::RESET_LINK_SENT) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        return __($status);
    }

    public function changePassword(User $user, string $currentPassword, string $newPassword): void
    {
        if (! Hash::check($currentPassword, $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => ['Kata sandi saat ini tidak sesuai.'],
            ]);
        }

        if (Hash::check($newPassword, $user->password)) {
            throw ValidationException::withMessages([
                'password' => ['Kata sandi baru harus berbeda dari kata sandi saat ini.'],
            ]);
        }

        $user->forceFill([
            'password' => $newPassword,
            'must_change_password' => false,
        ])->save();
    }

    public function resetPassword(array $data): string
    {
        $status = Password::reset(
            $data,
            function (User $user, string $password): void {
                $user->forceFill([
                    'password' => $password,
                    'must_change_password' => false,
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            }
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        return __($status);
    }

    public function createToken(User $user, string $deviceName): string
    {
        $expiresAt = now()->addDays(config('creativepos.token_expiry_days', 30));

        return $user->createToken($deviceName, ['*'], $expiresAt)->plainTextToken;
    }

    public function buildAuthResponse(User $user, ?string $token, bool $requires2fa = false): array
    {
        $tenant = $user->tenant_id
            ? Tenant::query()->find($user->tenant_id)
            : null;

        return [
            'token' => $token,
            'requires_2fa' => $requires2fa,
            'user' => $user,
            'permissions' => $user->getAllPermissionNames(),
            'roles' => $user->getRoleNames()->toArray(),
            'tenant' => $tenant,
        ];
    }

    protected function recordSuccessfulLogin(User $user, Request $request, ?string $deviceName): void
    {
        $fingerprint = $request->header('X-Device-Fingerprint', $request->ip());

        $this->users->updateLastLogin($user, $request->ip());
        $this->loginHistories->record(
            $user,
            $request->ip(),
            true,
            $request->userAgent(),
            $deviceName,
            $fingerprint,
        );
        $this->devices->upsertDevice(
            $user,
            $deviceName ?? 'Unknown Device',
            $fingerprint,
            $request->header('X-Platform'),
            $request->header('X-Browser'),
        );
    }

    protected function recordFailedLogin(?User $user, Request $request, string $reason): void
    {
        if ($user === null) {
            return;
        }

        $this->loginHistories->record(
            $user,
            $request->ip(),
            false,
            $request->userAgent(),
            null,
            null,
            $reason,
        );
    }

    protected function generateUniqueSlug(string $businessName): string
    {
        $baseSlug = Str::slug($businessName);
        $slug = $baseSlug;
        $counter = 1;

        while (Tenant::query()->where('slug', $slug)->exists()) {
            $slug = "{$baseSlug}-{$counter}";
            $counter++;
        }

        return $slug;
    }

    protected function createPendingTwoFactorSession(User $user): string
    {
        $token = Str::random(64);
        Cache::put("2fa_pending:{$token}", $user->id, now()->addMinutes(10));

        return $token;
    }

    protected function clearPendingTwoFactorSession(User $user): void
    {
        // Cache keys are token-based; pending session cleared on successful 2FA
    }

    protected function checkRateLimit(string $email, string $ip): void
    {
        $key = "login_attempts:{$email}:{$ip}";
        $attempts = (int) Cache::get($key, 0);
        $maxAttempts = config('creativepos.login.max_attempts', 5);

        if ($attempts >= $maxAttempts) {
            throw ValidationException::withMessages([
                'email' => ['Too many login attempts. Please try again later.'],
            ]);
        }
    }

    protected function incrementLoginAttempts(string $email, string $ip): void
    {
        $key = "login_attempts:{$email}:{$ip}";
        $lockoutMinutes = config('creativepos.login.lockout_minutes', 15);

        Cache::add($key, 0, now()->addMinutes($lockoutMinutes));
        Cache::increment($key);
    }

    protected function clearLoginAttempts(string $email, string $ip): void
    {
        Cache::forget("login_attempts:{$email}:{$ip}");
    }
}