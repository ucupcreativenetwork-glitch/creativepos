<?php

use App\Modules\Billing\Controllers\BillingController;
use Illuminate\Support\Facades\Route;

Route::prefix('billing')->group(function (): void {
    Route::get('/subscription', [BillingController::class, 'subscription']);
    Route::get('/payment-methods', [BillingController::class, 'paymentMethods']);
    Route::post('/subscription/recurring', [BillingController::class, 'setupRecurring']);
    Route::get('/invoices', [BillingController::class, 'invoices']);
    Route::get('/invoices/{invoice}', [BillingController::class, 'showInvoice']);
    Route::post('/invoices/{invoice}/pay', [BillingController::class, 'initiatePayment']);
    Route::get('/invoices/{invoice}/payment-status', [BillingController::class, 'paymentStatus']);
});