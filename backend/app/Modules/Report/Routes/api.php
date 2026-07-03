<?php

use App\Modules\Report\Controllers\ReportController;
use Illuminate\Support\Facades\Route;

Route::prefix('reports')->group(function (): void {
    Route::get('/sales', [ReportController::class, 'sales']);
    Route::get('/products', [ReportController::class, 'products']);
    Route::get('/inventory', [ReportController::class, 'inventory']);
    Route::get('/members', [ReportController::class, 'members']);
    Route::get('/profit-loss', [ReportController::class, 'profitLoss']);
    Route::get('/cash-flow', [ReportController::class, 'cashFlow']);

    Route::post('/export', [ReportController::class, 'export']);
    Route::get('/export/{export}', [ReportController::class, 'showExport']);
    Route::get('/export/{export}/download', [ReportController::class, 'downloadExport']);

    Route::get('/exports', [ReportController::class, 'exports']);
    Route::get('/exports/{export}/download', [ReportController::class, 'downloadExport']);
});