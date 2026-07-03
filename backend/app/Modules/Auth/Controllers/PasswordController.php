<?php

namespace App\Modules\Auth\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Services\AuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rules\Password;

class PasswordController extends Controller
{
    public function __construct(
        private readonly AuthService $authService,
    ) {}

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate([
            'email' => ['required', 'email'],
        ]);

        $this->authService->sendPasswordResetLink($request->input('email'));

        return $this->success(
            null,
            'If an account exists with that email, a password reset link has been sent.',
        );
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'string', 'confirmed', Password::min(8)->mixedCase()->numbers()],
        ]);

        $this->authService->resetPassword($request->only(
            'email',
            'password',
            'password_confirmation',
            'token',
        ));

        return $this->success(null, 'Password has been reset successfully.');
    }
}