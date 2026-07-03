<?php

namespace App\Modules\Auth\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Enums\OtpChannel;
use App\Modules\Auth\Enums\OtpPurpose;
use App\Modules\Auth\Repositories\UserRepository;
use App\Modules\Auth\Services\AuthService;
use App\Modules\Auth\Services\OtpService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class OtpController extends Controller
{
    public function __construct(
        private readonly OtpService $otpService,
        private readonly AuthService $authService,
        private readonly UserRepository $users,
    ) {}

    public function sendWhatsApp(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => ['required', 'string', 'max:20'],
            'purpose' => ['required', Rule::enum(OtpPurpose::class)],
        ]);

        $purpose = OtpPurpose::from($request->input('purpose'));
        $tenantId = null;
        $userName = null;

        if ($purpose === OtpPurpose::Login) {
            $user = $this->users->findByPhone($request->input('phone'));

            if ($user === null) {
                return $this->error('No account found with this phone number.', 404);
            }

            $tenantId = $user->tenant_id;
            $userName = $user->name;
        }

        $result = $this->otpService->send(
            $request->input('phone'),
            OtpChannel::Whatsapp,
            $purpose,
            $tenantId,
            $userName,
        );

        return $this->success($result, 'OTP sent via WhatsApp.');
    }

    public function sendEmail(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
            'purpose' => ['required', Rule::enum(OtpPurpose::class)],
        ]);

        $purpose = OtpPurpose::from($request->input('purpose'));
        $tenantId = null;

        $userName = null;

        if ($purpose === OtpPurpose::Login) {
            $user = $this->users->findByEmail($request->input('email'));

            if ($user === null) {
                return $this->error('No account found with this email.', 404);
            }

            $tenantId = $user->tenant_id;
            $userName = $user->name;
        }

        $result = $this->otpService->send(
            $request->input('email'),
            OtpChannel::Email,
            $purpose,
            $tenantId,
            $userName,
        );

        return $this->success($result, 'OTP sent via email.');
    }

    public function verify(Request $request): JsonResponse
    {
        $request->validate([
            'identifier' => ['required', 'string'],
            'code' => ['required', 'string', 'size:6'],
            'channel' => ['required', Rule::enum(OtpChannel::class)],
            'purpose' => ['required', Rule::enum(OtpPurpose::class)],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $channel = OtpChannel::from($request->input('channel'));
        $purpose = OtpPurpose::from($request->input('purpose'));

        $this->otpService->verify(
            $request->input('identifier'),
            $request->input('code'),
            $channel,
            $purpose,
        );

        if ($purpose === OtpPurpose::Login) {
            $user = $channel === OtpChannel::Whatsapp
                ? $this->users->findByPhone($request->input('identifier'))
                : $this->users->findByEmail($request->input('identifier'));

            if ($user === null) {
                return $this->error('User not found.', 404);
            }

            return $this->success(
                new \App\Modules\Auth\Resources\AuthResource(
                    $this->authService->completeOtpLogin(
                        $user,
                        $request,
                        $request->input('device_name', 'OTP Login'),
                    )
                ),
                'OTP verified. Login successful.',
            );
        }

        return $this->success(null, 'OTP verified successfully.');
    }
}