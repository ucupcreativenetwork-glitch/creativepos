<?php

use App\Modules\Notification\Controllers\DeviceController;
use App\Modules\Notification\Controllers\NotificationController;
use Illuminate\Support\Facades\Route;

Route::prefix('notifications')->group(function (): void {
    Route::get('/', [NotificationController::class, 'index']);
    Route::get('/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/read-all', [NotificationController::class, 'markAllRead']);
    Route::patch('/{notification}/read', [NotificationController::class, 'markRead']);
    Route::get('/preferences', [NotificationController::class, 'preferences']);
    Route::put('/preferences', [NotificationController::class, 'updatePreferences']);
});

Route::post('/devices/fcm-token', [DeviceController::class, 'registerFcmToken']);