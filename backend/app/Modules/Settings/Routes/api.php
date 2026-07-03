<?php

use App\Modules\Settings\Controllers\SettingsController;
use App\Modules\Settings\Controllers\UploadController;
use Illuminate\Support\Facades\Route;

Route::post('/uploads', [UploadController::class, 'store']);

Route::prefix('settings')->group(function (): void {
    Route::get('/tenant', [SettingsController::class, 'getTenant']);
    Route::put('/tenant', [SettingsController::class, 'updateTenant']);
    Route::get('/onboarding-status', [SettingsController::class, 'onboardingStatus']);
    Route::get('/onboarding-checklist', [SettingsController::class, 'onboardingChecklist']);
    Route::patch('/onboarding-progress', [SettingsController::class, 'updateOnboardingProgress']);
    Route::post('/payment-methods', [SettingsController::class, 'syncPaymentMethods']);
    Route::get('/outlets', [SettingsController::class, 'outlets']);
    Route::post('/outlets', [SettingsController::class, 'storeOutlet']);
    Route::put('/outlets/{outlet}', [SettingsController::class, 'updateOutlet']);
    Route::get('/users', [SettingsController::class, 'users']);
    Route::get('/subscription', [SettingsController::class, 'subscription']);
    Route::get('/integrations', [SettingsController::class, 'integrations']);
    Route::get('/integrations/email', [SettingsController::class, 'getEmail']);
    Route::put('/integrations/email', [SettingsController::class, 'updateEmail']);
    Route::post('/integrations/email/test', [SettingsController::class, 'testEmail']);
    Route::get('/integrations/whatsapp', [SettingsController::class, 'getWhatsapp']);
    Route::put('/integrations/whatsapp', [SettingsController::class, 'updateWhatsapp']);
    Route::post('/integrations/whatsapp/test', [SettingsController::class, 'testWhatsapp']);
});