<?php

use App\Modules\Order\Controllers\PublicMenuController;
use Illuminate\Support\Facades\Route;

Route::prefix('public')->group(function (): void {
    Route::get('/menu/{tenantSlug}/{outletSlug}', [PublicMenuController::class, 'menu']);
    Route::get('/menu/{tenantSlug}/{outletSlug}/table/{token}', [PublicMenuController::class, 'tableMenu']);
    Route::post('/orders', [PublicMenuController::class, 'createOrder']);
    Route::get('/orders/{uuid}/track', [PublicMenuController::class, 'trackOrder']);
    Route::post('/call-waiter', [PublicMenuController::class, 'callWaiter']);
    Route::post('/request-bill', [PublicMenuController::class, 'requestBill']);
});