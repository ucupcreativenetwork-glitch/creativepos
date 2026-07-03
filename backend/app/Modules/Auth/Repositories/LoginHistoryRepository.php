<?php

namespace App\Modules\Auth\Repositories;

use App\Models\User;
use App\Modules\Auth\Models\LoginHistory;
use App\Shared\Repositories\BaseRepository;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class LoginHistoryRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct(new LoginHistory);
    }

    public function record(
        User $user,
        string $ipAddress,
        bool $isSuccessful = true,
        ?string $userAgent = null,
        ?string $deviceName = null,
        ?string $deviceFingerprint = null,
        ?string $failureReason = null,
    ): LoginHistory {
        return $this->create([
            'user_id' => $user->id,
            'tenant_id' => $user->tenant_id,
            'ip_address' => $ipAddress,
            'user_agent' => $userAgent,
            'device_name' => $deviceName,
            'device_fingerprint' => $deviceFingerprint,
            'is_successful' => $isSuccessful,
            'failure_reason' => $failureReason,
            'logged_in_at' => now(),
        ]);
    }

    public function paginateForUser(User $user, int $perPage = 15): LengthAwarePaginator
    {
        return $this->query()
            ->where('user_id', $user->id)
            ->orderByDesc('logged_in_at')
            ->paginate($perPage);
    }

    public function markLoggedOut(User $user, ?int $tokenId = null): void
    {
        $this->query()
            ->where('user_id', $user->id)
            ->whereNull('logged_out_at')
            ->update(['logged_out_at' => now()]);
    }
}