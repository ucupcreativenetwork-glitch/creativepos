<?php

use App\Modules\Order\Controllers\KitchenController;
use App\Modules\Order\Controllers\OrderController;
use App\Modules\Order\Controllers\TableController;
use App\Modules\Order\Controllers\TableServiceRequestController;

use Illuminate\Support\Facades\Route;

Route::prefix('tables')->group(function (): void {
    Route::get('/', [TableController::class, 'index']);
    Route::post('/', [TableController::class, 'store']);
    Route::put('/{table}', [TableController::class, 'update']);
    Route::post('/{table}/qr', [TableController::class, 'generateQr']);
});

Route::prefix('orders')->group(function (): void {
    Route::get('/', [OrderController::class, 'index']);
    Route::post('/', [OrderController::class, 'store']);
    Route::get('/{order}', [OrderController::class, 'show']);
    Route::patch('/{order}/status', [OrderController::class, 'updateStatus']);
});

Route::prefix('kitchen')->group(function (): void {
    Route::get('/queue', [KitchenController::class, 'queue']);
    Route::patch('/orders/{order}/bump', [KitchenController::class, 'bump']);
});

Route::prefix('table-service-requests')->group(function (): void {
    Route::get('/', [TableServiceRequestController::class, 'index']);
    Route::patch('/{uuid}/acknowledge', [TableServiceRequestController::class, 'acknowledge']);
});