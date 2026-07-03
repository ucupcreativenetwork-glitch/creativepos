<?php

use App\Modules\POS\Controllers\CatalogController;
use App\Modules\POS\Controllers\HeldTransactionController;
use App\Modules\POS\Controllers\ShiftController;
use App\Modules\POS\Controllers\TransactionController;
use Illuminate\Support\Facades\Route;

Route::prefix('pos')->group(function (): void {
    Route::get('/catalog/products', [CatalogController::class, 'products']);
    Route::get('/catalog/categories', [CatalogController::class, 'categories']);
    Route::get('/catalog/payment-methods', [CatalogController::class, 'paymentMethods']);

    Route::get('/shifts/current', [ShiftController::class, 'current']);
    Route::post('/shifts/open', [ShiftController::class, 'open']);
    Route::post('/shifts/{shift}/close', [ShiftController::class, 'close']);
    Route::get('/shifts/{shift}/report', [ShiftController::class, 'report']);

    Route::prefix('held')->group(function (): void {
        Route::get('/', [HeldTransactionController::class, 'index']);
        Route::post('/', [HeldTransactionController::class, 'store']);
        Route::post('/{held}/resume', [HeldTransactionController::class, 'resume']);
        Route::delete('/{held}', [HeldTransactionController::class, 'destroy']);
    });

    Route::get('/transactions', [TransactionController::class, 'index']);
    Route::get('/transactions/{transaction}', [TransactionController::class, 'show']);
    // POST /transactions → didaftarkan di routes/api.php dengan middleware idempotency
    Route::post('/transactions/{transaction}/void', [TransactionController::class, 'void']);
    Route::get('/transactions/{transaction}/receipt', [TransactionController::class, 'receipt']);
});