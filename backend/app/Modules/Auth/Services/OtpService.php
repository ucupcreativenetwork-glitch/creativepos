<?php

namespace App\Modules\Auth\Services;

use App\Modules\Auth\Enums\OtpChannel;
use App\Modules\Auth\Enums\OtpPurpose;
use App\Modules\Auth\Jobs\SendOtpJob;
use App\Modules\Auth\Repositories\OtpVerificationRepository;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class OtpService
{
    public function __construct(
        private readonly OtpVerificationRepository $otpRepository,
    ) {}

    public function send(
        string $identifier,
        OtpChannel $channel,
        OtpPurpose $purpose,
        ?int $tenantId = null,
        ?string $userName = null,
    ): array {
        $code = $this->generateCode();
        $otp = $this->otpRepository->createOtp($identifier, $code, $channel, $purpose, $tenantId);

        SendOtpJob::dispatch($identifier, $code, $channel, $purpose->value, $tenantId, $userName);

        return [
            'expires_in' => max(0, (int) now()->diffInSeconds($otp->expires_at, false)),
            'expires_at' => $otp->expires_at->toIso8601String(),
        ];
    }

    public function verify(
        string $identifier,
        string $code,
        OtpChannel $channel,
        OtpPurpose $purpose,
    ): bool {
        $otp = $this->otpRepository->findValidOtp($identifier, $channel, $purpose);

        if ($otp === null) {
            throw ValidationException::withMessages([
                'code' => ['OTP is invalid or has expired.'],
            ]);
        }

        if ($otp->hasExceededAttempts()) {
            throw ValidationException::withMessages([
                'code' => ['Maximum verification attempts exceeded. Please request a new OTP.'],
            ]);
        }

        if (! Hash::check($code, $otp->code_hash)) {
            $this->otpRepository->incrementAttempts($otp);

            throw ValidationException::withMessages([
                'code' => ['Invalid OTP code.'],
            ]);
        }

        $this->otpRepository->markVerified($otp);

        return true;
    }

    protected function generateCode(): string
    {
        $length = config('creativepos.otp.code_length', 6);

        return str_pad((string) random_int(0, (10 ** $length) - 1), $length, '0', STR_PAD_LEFT);
    }
}