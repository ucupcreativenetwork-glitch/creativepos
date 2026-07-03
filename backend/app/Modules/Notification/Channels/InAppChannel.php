<?php

namespace App\Modules\Notification\Channels;

use App\Modules\Notification\Enums\NotificationChannel;
use App\Modules\Notification\Models\AppNotification;
use App\Modules\Notification\Services\NotificationLogService;
use Illuminate\Notifications\Notification;

class InAppChannel
{
    public function __construct(
        private readonly NotificationLogService $logService,
    ) {}

    public function send(object $notifiable, Notification $notification): void
    {
        if (! method_exists($notification, 'toInApp')) {
            return;
        }

        $payload = $notification->toInApp($notifiable);

        AppNotification::query()->create([
            'tenant_id' => $notifiable->tenant_id ?? tenant('id'),
            'user_id' => $notifiable->id,
            'type' => $payload['type'] ?? 'general',
            'title' => $payload['title'] ?? 'Notifikasi',
            'body' => $payload['body'] ?? null,
            'data' => $payload['data'] ?? null,
            'created_at' => now(),
        ]);

        $event = method_exists($notification, 'eventType')
            ? $notification->eventType()
            : null;

        if ($event !== null) {
            $this->logService->record(
                event: $event,
                channel: NotificationChannel::InApp,
                status: 'sent',
                user: $notifiable instanceof \App\Models\User ? $notifiable : null,
                recipient: (string) $notifiable->id,
                message: ($payload['title'] ?? '').': '.($payload['body'] ?? ''),
                dedupKey: method_exists($notification, 'dedupKey') ? $notification->dedupKey() : null,
            );
        }
    }
}