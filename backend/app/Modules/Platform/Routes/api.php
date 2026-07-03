<?php

use App\Modules\Mobile\Controllers\AppReleaseAdminController;
use App\Modules\Platform\Controllers\BillingAdminController;
use App\Modules\Platform\Controllers\PackageController;
use App\Modules\Platform\Controllers\PlatformDashboardController;
use App\Modules\Platform\Controllers\TenantController;
use App\Modules\RemoteSupport\Controllers\PlatformDeviceController;
use Illuminate\Support\Facades\Route;

Route::get('/dashboard', [PlatformDashboardController::class, 'index']);
Route::get('/tenants', [TenantController::class, 'index']);
Route::patch('/tenants/{tenant}/suspend', [TenantController::class, 'suspend']);
Route::patch('/tenants/{tenant}/activate', [TenantController::class, 'activate']);
Route::get('/packages', [PackageController::class, 'index']);
Route::get('/billing/invoices', [BillingAdminController::class, 'index']);
Route::post('/billing/invoices', [BillingAdminController::class, 'store']);

Route::prefix('devices')->group(function (): void {
    Route::get('/stats', [PlatformDeviceController::class, 'stats']);
    Route::get('/', [PlatformDeviceController::class, 'index']);
    Route::get('/{device}', [PlatformDeviceController::class, 'show']);
    Route::post('/{device}/commands', [PlatformDeviceController::class, 'queueCommand']);
});

Route::prefix('app-releases')->group(function (): void {
    Route::get('/', [AppReleaseAdminController::class, 'index']);
    Route::post('/', [AppReleaseAdminController::class, 'store']);
    Route::patch('/{release}/activate', [AppReleaseAdminController::class, 'activate']);
    Route::delete('/{release}', [AppReleaseAdminController::class, 'destroy']);
});