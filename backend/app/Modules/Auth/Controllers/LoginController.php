<?php

namespace App\Modules\Auth\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Requests\LoginRequest;
use App\Modules\Auth\Resources\AuthResource;
use App\Modules\Auth\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LoginController extends Controller
{
    public function __construct(
        private readonly AuthService $authService,
    ) {}

    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login(
            $request->validated(),
            $request,
        );

        if ($result['requires_2fa'] ?? false) {
            return $this->success(
                new AuthResource($result),
                'Two-factor authentication required.',
            );
        }

        return $this->success(
            new AuthResource($result),
            'Login successful.',
        );
    }

    public function verifyTwoFactor(Request $request): JsonResponse
    {
        $request->validate([
            'pending_token' => ['required', 'string'],
            'code' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $user = $this->authService->getPendingTwoFactorUser($request->input('pending_token'));

        if ($user === null) {
            return $this->error('Invalid or expired two-factor session.', 401);
        }

        $result = $this->authService->completeTwoFactorLogin(
            $user,
            $request->input('code'),
            $request,
            $request->input('device_name'),
        );

        return $this->success(
            new AuthResource($result),
            'Login successful.',
        );
    }

    public function me(Request $request): JsonResponse
    {
        $result = $this->authService->me($request->user());

        return $this->success(
            new AuthResource($result),
            'User profile retrieved.',
        );
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout(
            $request->user(),
            $request->user()->currentAccessToken()?->id,
        );

        return $this->success(null, 'Logged out successfully.');
    }
}