<?php

use App\Modules\Delivery\Controllers\DeliveryDriverController;
use App\Modules\Delivery\Controllers\DeliveryOrderController;
use App\Modules\Delivery\Controllers\DeliveryZoneController;
use Illuminate\Support\Facades\Route;

Route::prefix('delivery')->group(function (): void {
    Route::get('/orders', [DeliveryOrderController::class, 'index']);
    Route::post('/orders', [DeliveryOrderController::class, 'store']);
    Route::get('/orders/{deliveryOrder}', [DeliveryOrderController::class, 'show']);
    Route::patch('/orders/{deliveryOrder}/status', [DeliveryOrderController::class, 'updateStatus']);
    Route::post('/orders/{deliveryOrder}/assign', [DeliveryOrderController::class, 'assign']);
    Route::post('/orders/{deliveryOrder}/location', [DeliveryOrderController::class, 'location']);

    Route::get('/drivers', [DeliveryDriverController::class, 'index']);
    Route::post('/drivers', [DeliveryDriverController::class, 'store']);
    Route::get('/zones', [DeliveryZoneController::class, 'index']);
    Route::post('/zones', [DeliveryZoneController::class, 'store']);
    Route::post('/calculate-fee', [DeliveryZoneController::class, 'calculateFee']);
});