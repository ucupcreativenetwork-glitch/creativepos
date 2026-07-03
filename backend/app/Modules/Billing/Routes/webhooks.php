<?php

use App\Modules\Billing\Controllers\PaymentWebhookController;
use Illuminate\Support\Facades\Route;

Route::prefix('webhooks/payment')->group(function (): void {
    Route::post('/midtrans', [PaymentWebhookController::class, 'midtrans']);
    Route::post('/xendit', [PaymentWebhookController::class, 'xendit']);
});