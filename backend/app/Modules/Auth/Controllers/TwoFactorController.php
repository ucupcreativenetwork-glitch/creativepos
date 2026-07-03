<?php

namespace App\Modules\Auth\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Resources\UserResource;
use App\Modules\Auth\Services\TwoFactorService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TwoFactorController extends Controller
{
    public function __construct(
        private readonly TwoFactorService $twoFactorService,
    ) {}

    public function setup(Request $request): JsonResponse
    {
        $user = $request->user();
        $secret = $this->twoFactorService->generateSecret();

        return $this->success([
            'secret' => $secret,
            'qr_code_url' => $this->twoFactorService->getQrCodeUrl($user, $secret),
        ], 'Scan the QR code with your authenticator app.');
    }

    public function enable(Request $request): JsonResponse
    {
        $request->validate([
            'secret' => ['required', 'string'],
            'code' => ['required', 'string', 'size:6'],
        ]);

        $user = $this->twoFactorService->enableTotp(
            $request->user(),
            $request->input('secret'),
            $request->input('code'),
        );

        return $this->success(
            new UserResource($user),
            'Two-factor authentication enabled.',
        );
    }

    public function disable(Request $request): JsonResponse
    {
        $request->validate([
            'code' => ['required', 'string'],
        ]);

        if (! $this->twoFactorService->verify($request->user(), $request->input('code'))) {
            return $this->error('Invalid verification code.', 422);
        }

        $user = $this->twoFactorService->disable($request->user());

        return $this->success(
            new UserResource($user),
            'Two-factor authentication disabled.',
        );
    }

    public function sendChallenge(Request $request): JsonResponse
    {
        $result = $this->twoFactorService->sendChallenge($request->user());

        return $this->success($result, 'Verification code sent.');
    }
}