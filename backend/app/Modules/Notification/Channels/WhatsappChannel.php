<?php

namespace App\Modules\Notification\Channels;

use App\Modules\Notification\Enums\NotificationChannel;
use App\Modules\Notification\Services\NotificationLogService;
use App\Modules\Notification\Services\WhatsappService;
use Illuminate\Notifications\Notification;

class WhatsappChannel
{
    public function __construct(
        private readonly WhatsappService $whatsappService,
        private readonly NotificationLogService $logService,
    ) {}

    public function send(object $notifiable, Notification $notification): void
    {
        if (! method_exists($notification, 'toWhatsapp')) {
            return;
        }

        $message = $notification->toWhatsapp($notifiable);
        $phone = $notifiable->routeNotificationForWhatsapp();

        if (blank($phone)) {
            return;
        }

        $event = method_exists($notification, 'eventType')
            ? $notification->eventType()
            : null;

        $result = $this->whatsappService->send(
            $phone,
            $message,
            $notifiable->tenant_id ?? tenant('id'),
        );

        if ($event !== null) {
            $this->logService->record(
                event: $event,
                channel: NotificationChannel::Whatsapp,
                status: $result['success'] ? 'sent' : 'failed',
                user: $notifiable instanceof \App\Models\User ? $notifiable : null,
                recipient: $phone,
                message: $message,
                response: $result['response'] ?? ['error' => $result['error'] ?? null],
                dedupKey: method_exists($notification, 'dedupKey') ? $notification->dedupKey() : null,
            );
        }
    }
}