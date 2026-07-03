<?php

use App\Modules\Mobile\Controllers\MobileController;
use Illuminate\Support\Facades\Route;

Route::prefix('mobile')->group(function (): void {
    Route::get('/version', [MobileController::class, 'version']);
    Route::get('/download/{release}', [MobileController::class, 'download'])
        ->name('mobile.download');
});