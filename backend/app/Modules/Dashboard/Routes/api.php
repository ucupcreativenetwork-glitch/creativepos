<?php

use App\Modules\Dashboard\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;

Route::prefix('dashboard')->group(function (): void {
    Route::get('/kpi', [DashboardController::class, 'kpi']);
    Route::get('/charts/sales', [DashboardController::class, 'salesChart']);
    Route::get('/charts/products', [DashboardController::class, 'productPerformance']);
    Route::get('/charts/customers', [DashboardController::class, 'customerGrowth']);
    Route::get('/charts/outlets', [DashboardController::class, 'outletPerformance']);
    Route::get('/live-feed', [DashboardController::class, 'liveFeed']);
    Route::get('/outlets', [DashboardController::class, 'outlets']);
});