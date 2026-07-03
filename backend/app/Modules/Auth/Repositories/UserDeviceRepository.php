<?php

namespace App\Modules\Auth\Repositories;

use App\Models\User;
use App\Modules\Auth\Models\UserDevice;
use App\Shared\Repositories\BaseRepository;

class UserDeviceRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct(new UserDevice);
    }

    public function upsertDevice(
        User $user,
        string $deviceName,
        string $fingerprint,
        ?string $platform = null,
        ?string $browser = null,
    ): UserDevice {
        return $this->query()->updateOrCreate(
            [
                'user_id' => $user->id,
                'fingerprint' => $fingerprint,
            ],
            [
                'device_name' => $deviceName,
                'platform' => $platform,
                'browser' => $browser,
                'last_used_at' => now(),
            ]
        );
    }

    public function findByFingerprint(User $user, string $fingerprint): ?UserDevice
    {
        return $this->query()
            ->where('user_id', $user->id)
            ->where('fingerprint', $fingerprint)
            ->first();
    }
}