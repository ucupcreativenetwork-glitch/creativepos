<?php

use App\Modules\Reservation\Controllers\ReservationController;
use App\Modules\Reservation\Controllers\TimeSlotController;
use Illuminate\Support\Facades\Route;

Route::prefix('reservations')->group(function (): void {
    Route::get('/time-slots', [TimeSlotController::class, 'index']);
    Route::post('/time-slots', [TimeSlotController::class, 'store']);
    Route::put('/time-slots/{timeSlot}', [TimeSlotController::class, 'update']);
    Route::delete('/time-slots/{timeSlot}', [TimeSlotController::class, 'destroy']);

    Route::get('/', [ReservationController::class, 'index']);
    Route::post('/', [ReservationController::class, 'store']);
    Route::get('/calendar', [ReservationController::class, 'calendar']);
    Route::get('/slots', [ReservationController::class, 'slots']);
    Route::get('/{reservation}', [ReservationController::class, 'show']);
    Route::put('/{reservation}', [ReservationController::class, 'update']);
    Route::patch('/{reservation}/status', [ReservationController::class, 'updateStatus']);
});