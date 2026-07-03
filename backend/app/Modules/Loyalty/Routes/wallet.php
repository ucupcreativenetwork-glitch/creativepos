<?php

use App\Modules\Loyalty\Controllers\WalletController;
use Illuminate\Support\Facades\Route;

Route::prefix('wallet')->group(function (): void {
    Route::get('/{member}', [WalletController::class, 'show']);
    Route::get('/{member}/transactions', [WalletController::class, 'transactions']);
    Route::post('/topup', [WalletController::class, 'topup']);
    Route::post('/withdraw', [WalletController::class, 'withdraw']);
    Route::post('/transfer', [WalletController::class, 'transfer']);
});