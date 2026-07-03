<?php

namespace App\Modules\Auth\Repositories;

use App\Modules\Auth\Enums\OtpChannel;
use App\Modules\Auth\Enums\OtpPurpose;
use App\Modules\Auth\Models\OtpVerification;
use App\Shared\Repositories\BaseRepository;
use Illuminate\Support\Facades\Hash;

class OtpVerificationRepository extends BaseRepository
{
    public function __construct()
    {
        parent::__construct(new OtpVerification);
    }

    public function createOtp(
        string $identifier,
        string $code,
        OtpChannel $channel,
        OtpPurpose $purpose,
        ?int $tenantId = null,
    ): OtpVerification {
        $this->invalidatePending($identifier, $channel, $purpose);

        return $this->create([
            'tenant_id' => $tenantId,
            'identifier' => $identifier,
            'channel' => $channel,
            'code_hash' => Hash::make($code),
            'purpose' => $purpose,
            'attempts' => 0,
            'max_attempts' => config('creativepos.otp.max_attempts', 5),
            'expires_at' => now()->addMinutes(config('creativepos.otp.expiry_minutes', 5)),
            'created_at' => now(),
        ]);
    }

    public function findValidOtp(
        string $identifier,
        OtpChannel $channel,
        OtpPurpose $purpose,
    ): ?OtpVerification {
        return $this->query()
            ->where('identifier', $identifier)
            ->where('channel', $channel)
            ->where('purpose', $purpose)
            ->whereNull('verified_at')
            ->where('expires_at', '>', now())
            ->latest('created_at')
            ->first();
    }

    public function invalidatePending(
        string $identifier,
        OtpChannel $channel,
        OtpPurpose $purpose,
    ): void {
        $this->query()
            ->where('identifier', $identifier)
            ->where('channel', $channel)
            ->where('purpose', $purpose)
            ->whereNull('verified_at')
            ->update(['verified_at' => now()]);
    }

    public function incrementAttempts(OtpVerification $otp): OtpVerification
    {
        $otp->increment('attempts');

        return $otp->fresh();
    }

    public function markVerified(OtpVerification $otp): OtpVerification
    {
        $otp->update(['verified_at' => now()]);

        return $otp->fresh();
    }
}