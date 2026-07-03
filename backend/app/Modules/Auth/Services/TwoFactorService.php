<?php

namespace App\Modules\Auth\Services;

use App\Models\User;
use App\Modules\Auth\Enums\TwoFactorMethod;
use App\Modules\Auth\Repositories\UserRepository;
use Illuminate\Support\Facades\Crypt;
use Illuminate\Validation\ValidationException;
use PragmaRX\Google2FA\Google2FA;

class TwoFactorService
{
    public function __construct(
        private readonly Google2FA $google2fa,
        private readonly UserRepository $users,
        private readonly OtpService $otpService,
    ) {}

    public function generateSecret(): string
    {
        return $this->google2fa->generateSecretKey();
    }

    public function getQrCodeUrl(User $user, string $secret): string
    {
        return $this->google2fa->getQRCodeUrl(
            config('creativepos.name', 'CreativePOS'),
            $user->email,
            $secret,
        );
    }

    public function enableTotp(User $user, string $secret, string $code): User
    {
        if (! $this->verifyTotpCode($secret, $code)) {
            throw ValidationException::withMessages([
                'code' => ['Invalid authenticator code.'],
            ]);
        }

        return $this->users->update($user, [
            'two_factor_enabled' => true,
            'two_factor_secret' => Crypt::encryptString($secret),
            'two_factor_method' => TwoFactorMethod::Totp,
        ]);
    }

    public function disable(User $user): User
    {
        return $this->users->update($user, [
            'two_factor_enabled' => false,
            'two_factor_secret' => null,
            'two_factor_method' => null,
        ]);
    }

    public function verify(User $user, string $code): bool
    {
        if (! $user->requiresTwoFactor()) {
            return true;
        }

        return match ($user->two_factor_method) {
            TwoFactorMethod::Totp->value => $this->verifyTotpCode(
                Crypt::decryptString($user->two_factor_secret),
                $code
            ),
            TwoFactorMethod::Whatsapp->value, TwoFactorMethod::Email->value => $this->verifyChannelOtp($user, $code),
            default => false,
        };
    }

    public function sendChallenge(User $user): array
    {
        $identifier = match ($user->two_factor_method) {
            TwoFactorMethod::Whatsapp->value => $user->phone,
            TwoFactorMethod::Email->value => $user->email,
            default => throw ValidationException::withMessages([
                'two_factor' => ['TOTP challenge does not require OTP delivery.'],
            ]),
        };

        if (blank($identifier)) {
            throw ValidationException::withMessages([
                'two_factor' => ['No contact method available for 2FA.'],
            ]);
        }

        $channel = $user->two_factor_method === TwoFactorMethod::Whatsapp->value
            ? \App\Modules\Auth\Enums\OtpChannel::Whatsapp
            : \App\Modules\Auth\Enums\OtpChannel::Email;

        return $this->otpService->send(
            $identifier,
            $channel,
            \App\Modules\Auth\Enums\OtpPurpose::Login,
            $user->tenant_id,
            $user->name,
        );
    }

    protected function verifyTotpCode(string $secret, string $code): bool
    {
        return $this->google2fa->verifyKey($secret, $code);
    }

    protected function verifyChannelOtp(User $user, string $code): bool
    {
        $identifier = $user->two_factor_method === TwoFactorMethod::Whatsapp->value
            ? $user->phone
            : $user->email;

        $channel = $user->two_factor_method === TwoFactorMethod::Whatsapp->value
            ? \App\Modules\Auth\Enums\OtpChannel::Whatsapp
            : \App\Modules\Auth\Enums\OtpChannel::Email;

        return $this->otpService->verify(
            $identifier,
            $code,
            $channel,
            \App\Modules\Auth\Enums\OtpPurpose::Login,
        );
    }
}