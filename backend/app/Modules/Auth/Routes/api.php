<?php

use App\Modules\Auth\Controllers\InviteController;
use App\Modules\Auth\Controllers\LoginController;
use App\Modules\Auth\Controllers\OtpController;
use App\Modules\Auth\Controllers\PasswordController;
use App\Modules\Auth\Controllers\RegisterController;
use App\Modules\Auth\Controllers\SessionController;
use App\Modules\Auth\Controllers\TwoFactorController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->name('auth.')->group(function (): void {
    // Public routes
    Route::middleware('throttle:auth')->group(function (): void {
        Route::post('register', [RegisterController::class, 'register'])->name('register');
        Route::post('login', [LoginController::class, 'login'])->name('login');
        Route::post('login/2fa', [LoginController::class, 'verifyTwoFactor'])->name('login.2fa');

        Route::post('forgot-password', [PasswordController::class, 'forgotPassword'])->name('forgot-password');
        Route::post('reset-password', [PasswordController::class, 'resetPassword'])->name('reset-password');

        Route::post('otp/whatsapp', [OtpController::class, 'sendWhatsApp'])->name('otp.whatsapp');
        Route::post('otp/email', [OtpController::class, 'sendEmail'])->name('otp.email');
        Route::post('otp/verify', [OtpController::class, 'verify'])->name('otp.verify');
    });

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('me', [LoginController::class, 'me'])->name('me');
        Route::post('logout', [LoginController::class, 'logout'])->name('logout');
        Route::post('change-password', [PasswordController::class, 'changePassword'])->name('change-password');

        Route::get('sessions', [SessionController::class, 'index'])->name('sessions.index');
        Route::delete('sessions/{id}', [SessionController::class, 'destroy'])->name('sessions.destroy');
        Route::get('login-history', [SessionController::class, 'loginHistory'])->name('login-history');

        Route::prefix('2fa')->name('2fa.')->group(function (): void {
            Route::get('setup', [TwoFactorController::class, 'setup'])->name('setup');
            Route::post('enable', [TwoFactorController::class, 'enable'])->name('enable');
            Route::post('disable', [TwoFactorController::class, 'disable'])->name('disable');
            Route::post('challenge', [TwoFactorController::class, 'sendChallenge'])->name('challenge');
        });
    });
});