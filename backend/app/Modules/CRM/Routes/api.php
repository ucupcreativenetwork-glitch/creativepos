<?php

use App\Modules\CRM\Controllers\KnowledgeBaseController;
use App\Modules\CRM\Controllers\TicketController;
use Illuminate\Support\Facades\Route;

Route::prefix('crm')->group(function (): void {
    Route::get('/tickets', [TicketController::class, 'index']);
    Route::post('/tickets', [TicketController::class, 'store']);
    Route::get('/tickets/{ticket}', [TicketController::class, 'show']);
    Route::patch('/tickets/{ticket}/assign', [TicketController::class, 'assign']);
    Route::patch('/tickets/{ticket}/status', [TicketController::class, 'updateStatus']);
    Route::post('/tickets/{ticket}/messages', [TicketController::class, 'storeMessage']);
    Route::post('/tickets/{ticket}/rate', [TicketController::class, 'rate']);

    Route::get('/knowledge-base', [KnowledgeBaseController::class, 'knowledgeBase']);
    Route::get('/faqs', [KnowledgeBaseController::class, 'faqs']);

    Route::get('/whatsapp/config', [KnowledgeBaseController::class, 'showWhatsappConfig']);
    Route::put('/whatsapp/config', [KnowledgeBaseController::class, 'updateWhatsappConfig']);
});