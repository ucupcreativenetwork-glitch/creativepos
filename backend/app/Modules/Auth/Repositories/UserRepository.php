<?php

namespace App\Modules\Auth\Repositories;

use App\Models\User;
use App\Shared\Repositories\BaseRepository;
use Illuminate\Database\Eloquent\Model;

class UserRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct(new User);
    }

    public function findByEmail(string $email, ?int $tenantId = null): ?User
    {
        $query = $this->query()->where('email', $email);

        if ($tenantId !== null) {
            $query->where('tenant_id', $tenantId);
        }

        return $query->first();
    }

    public function findByPhone(string $phone, ?int $tenantId = null): ?User
    {
        $query = $this->query()->where('phone', $phone);

        if ($tenantId !== null) {
            $query->where('tenant_id', $tenantId);
        }

        return $query->first();
    }

    public function findSuperAdminByEmail(string $email): ?User
    {
        return $this->query()
            ->where('email', $email)
            ->where('is_super_admin', true)
            ->first();
    }

    public function updateLastLogin(User $user, string $ipAddress): User
    {
        return $this->update($user, [
            'last_login_at' => now(),
            'last_login_ip' => $ipAddress,
        ]);
    }

    public function emailExistsForTenant(string $email, ?int $tenantId): bool
    {
        return $this->query()
            ->where('email', $email)
            ->where('tenant_id', $tenantId)
            ->exists();
    }
}