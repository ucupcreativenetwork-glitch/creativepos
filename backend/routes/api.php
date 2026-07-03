<?php

use App\Modules\POS\Controllers\TransactionController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware('throttle:api')->group(function (): void {
    Route::get('/health', fn () => response()->json([
        'success' => true,
        'message' => 'CreativePOS API is running',
        'data' => [
            'service' => 'creativepos-api',
            'version' => '1.0.0',
            'timestamp' => now()->toIso8601String(),
        ],
    ]));

    // Public routes
    require app_path('Modules/Mobile/Routes/api.php');
    require app_path('Modules/Auth/Routes/api.php');
    require app_path('Modules/Order/Routes/public.php');
    require app_path('Modules/Billing/Routes/webhooks.php');

    // Authenticated tenant routes (future modules)
    Route::middleware(['auth:sanctum', 'password-changed', 'tenant', 'subscription', 'setup-check'])->group(function (): void {
        // Idempotency: cegah transaksi POS duplikat dari double-click / retry
        Route::middleware(['idempotency'])->post(
            '/pos/transactions',
            [TransactionController::class, 'store'],
        );

        require app_path('Modules/Dashboard/Routes/api.php');
        require app_path('Modules/Inventory/Routes/api.php');
        require app_path('Modules/POS/Routes/api.php');

        Route::middleware('feature:loyalty')->group(function (): void {
            require app_path('Modules/Loyalty/Routes/api.php');
        });

        Route::middleware('feature:wallet')->group(function (): void {
            require app_path('Modules/Loyalty/Routes/wallet.php');
        });

        Route::middleware('feature:order')->group(function (): void {
            require app_path('Modules/Order/Routes/api.php');
        });

        Route::middleware('feature:reservation')->group(function (): void {
            require app_path('Modules/Reservation/Routes/api.php');
        });

        Route::middleware('feature:delivery')->group(function (): void {
            require app_path('Modules/Delivery/Routes/api.php');
        });

        Route::middleware('feature:crm')->group(function (): void {
            require app_path('Modules/CRM/Routes/api.php');
        });

        Route::middleware('feature:report')->group(function (): void {
            require app_path('Modules/Report/Routes/api.php');
        });
        require app_path('Modules/Billing/Routes/api.php');
        require app_path('Modules/Notification/Routes/api.php');
        require app_path('Modules/RemoteSupport/Routes/api.php');
        require app_path('Modules/Settings/Routes/api.php');

        Route::prefix('auth')->name('auth.')->group(function (): void {
            Route::post('invite', [\App\Modules\Auth\Controllers\InviteController::class, 'invite'])
                ->name('invite');
        });
    });

    // Platform (Super Admin) routes
    Route::middleware(['auth:sanctum', 'password-changed', 'super-admin'])->prefix('platform')->group(function (): void {
        require app_path('Modules/Platform/Routes/api.php');
    });
});