<?php

use App\Modules\Loyalty\Controllers\MemberController;
use App\Modules\Loyalty\Controllers\PointConfigController;
use App\Modules\Loyalty\Controllers\PointController;
use App\Modules\Loyalty\Controllers\TierConfigController;
use Illuminate\Support\Facades\Route;

Route::get('/loyalty/point-config', [PointConfigController::class, 'show']);
Route::put('/loyalty/point-config', [PointConfigController::class, 'update']);
Route::put('/loyalty/tiers/{tier}', [TierConfigController::class, 'update']);

Route::prefix('members')->group(function (): void {
    Route::get('/tiers', [MemberController::class, 'tiers']);
    Route::get('/code/{code}', [MemberController::class, 'findByCode']);
    Route::get('/qr/{token}', [MemberController::class, 'findByQr']);
    Route::get('/', [MemberController::class, 'index']);
    Route::post('/', [MemberController::class, 'store']);
    Route::get('/{member}', [MemberController::class, 'show']);
    Route::put('/{member}', [MemberController::class, 'update']);
    Route::get('/{member}/points', [PointController::class, 'balance']);
    Route::post('/{member}/points/redeem', [PointController::class, 'redeem']);
    Route::post('/{member}/points/adjust', [PointController::class, 'adjust']);
});

