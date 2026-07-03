<?php

namespace App\Modules\Notification\Listeners;

use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Events\InvoiceDueEvent;
use App\Modules\Notification\Notifications\InvoiceDueNotification;
use App\Modules\Notification\Services\RecipientResolver;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Support\Facades\Notification;

class SendInvoiceDueNotification implements ShouldQueue
{
    public function __construct(
        private readonly RecipientResolver $recipientResolver,
    ) {}

    public function handle(InvoiceDueEvent $event): void
    {
        $invoice = $event->invoice;
        $tenant = $invoice->tenant;

        if ($tenant !== null) {
            set_tenant($tenant);
        }

        $recipients = $this->recipientResolver->resolve(NotificationEvent::InvoiceDue);

        Notification::send(
            $recipients,
            new InvoiceDueNotification($invoice, $event->dedupKey),
        );
    }
}