<?php

namespace App\Modules\Notification\Listeners;

use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Events\LowStockDetectedEvent;
use App\Modules\Notification\Notifications\LowStockNotification;
use App\Modules\Notification\Services\RecipientResolver;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Notification;

class SendLowStockNotification implements ShouldQueue
{
    public function __construct(
        private readonly RecipientResolver $recipientResolver,
    ) {}

    public function handle(LowStockDetectedEvent $event): void
    {
        $recipients = $this->recipientResolver->resolve(NotificationEvent::LowStock);
        $stock = $event->stock->loadMissing('warehouse:id,name,code');

        Notification::send(
            $recipients,
            new LowStockNotification(
                $event->product,
                $stock,
                $event->quantity,
                $event->minStock,
                $event->dedupKey,
            ),
        );
    }
}