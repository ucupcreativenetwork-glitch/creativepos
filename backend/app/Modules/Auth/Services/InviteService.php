<?php

namespace App\Modules\Auth\Services;

use App\Models\Role;
use App\Models\User;
use App\Modules\Auth\Repositories\UserRepository;
use App\Modules\Settings\Services\SettingsService;
use App\Shared\Services\PackageLimitService;
use App\Modules\Tenant\Models\Outlet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class InviteService
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly SettingsService $settingsService,
        private readonly PackageLimitService $packageLimits,
    ) {}

    public function invite(array $data): array
    {
        return DB::transaction(function () use ($data) {
            $tenantId = tenant('id') ?? auth()->user()?->tenant_id;

            if ($tenantId === null) {
                abort(403, 'Tenant context required.');
            }

            $this->packageLimits->assertCanInviteUser();

            if ($this->users->emailExistsForTenant($data['email'], $tenantId)) {
                throw ValidationException::withMessages([
                    'email' => ['Email sudah terdaftar di bisnis ini.'],
                ]);
            }

            $roleName = $data['role'] ?? 'cashier';
            if (! in_array($roleName, ['cashier', 'manager'], true)) {
                throw ValidationException::withMessages([
                    'role' => ['Role harus cashier atau manager.'],
                ]);
            }

            $role = Role::query()
                ->where('name', $roleName)
                ->whereNull('tenant_id')
                ->where('is_system', true)
                ->firstOrFail();

            $defaultOutlet = Outlet::query()
                ->where('tenant_id', $tenantId)
                ->where('is_default', true)
                ->first();

            $temporaryPassword = Str::password(12);

            $user = $this->users->create([
                'tenant_id' => $tenantId,
                'name' => $data['name'] ?? $this->deriveNameFromEmail($data['email']),
                'email' => $data['email'],
                'password' => $temporaryPassword,
                'outlet_id' => $defaultOutlet?->id,
                'status' => 'active',
            ]);

            $user->assignRole($role);

            $this->settingsService->updateOnboardingProgress([
                'staff_invited' => true,
                'completed_steps' => array_values(array_unique(array_merge(
                    $this->settingsService->getOnboardingStatus()['completed_steps'] ?? [],
                    ['staff'],
                ))),
            ]);

            return [
                'user' => [
                    'id' => $user->id,
                    'uuid' => $user->uuid,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $roleName,
                ],
                'temporary_password' => $temporaryPassword,
                'message' => 'Undangan staff berhasil. Bagikan kata sandi sementara kepada staff.',
            ];
        });
    }

    protected function deriveNameFromEmail(string $email): string
    {
        $local = Str::before($email, '@');

        return Str::title(str_replace(['.', '_', '-'], ' ', $local));
    }
}