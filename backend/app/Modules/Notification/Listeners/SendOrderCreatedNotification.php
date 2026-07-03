<?php

namespace App\Modules\Notification\Listeners;

use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Events\OrderCreatedEvent;
use App\Modules\Notification\Notifications\NewOrderNotification;
use App\Modules\Notification\Services\RecipientResolver;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Notification;

class SendOrderCreatedNotification implements ShouldQueue
{
    public function __construct(
        private readonly RecipientResolver $recipientResolver,
    ) {}

    public function handle(OrderCreatedEvent $event): void
    {
        $order = $event->order->loadMissing('items');
        $recipients = $this->recipientResolver->resolve(
            NotificationEvent::NewOrder,
            $order->outlet_id,
        );

        Notification::send($recipients, new NewOrderNotification($order));
    }
}