<?php

use App\Modules\RemoteSupport\Controllers\DeviceRemoteController;
use Illuminate\Support\Facades\Route;

Route::prefix('remote')->group(function (): void {
    Route::post('/register', [DeviceRemoteController::class, 'register']);
    Route::post('/heartbeat', [DeviceRemoteController::class, 'heartbeat']);
    Route::get('/commands', [DeviceRemoteController::class, 'pendingCommands']);
    Route::post('/commands/{command}/complete', [DeviceRemoteController::class, 'completeCommand']);
    Route::post('/diagnostics', [DeviceRemoteController::class, 'uploadDiagnostics']);
});