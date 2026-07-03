<?php

namespace App\Modules\Notification\Channels;

use App\Modules\Notification\Enums\NotificationChannel;
use App\Modules\Notification\Services\FirebaseService;
use App\Modules\Notification\Services\NotificationLogService;
use Illuminate\Notifications\Notification;

class FirebaseChannel
{
    public function __construct(
        private readonly FirebaseService $firebaseService,
        private readonly NotificationLogService $logService,
    ) {}

    public function send(object $notifiable, Notification $notification): void
    {
        if (! method_exists($notification, 'toFirebase')) {
            return;
        }

        $payload = $notification->toFirebase($notifiable);
        $tokens = $notifiable->routeNotificationForFcm();

        if ($tokens === []) {
            return;
        }

        $event = method_exists($notification, 'eventType')
            ? $notification->eventType()
            : null;

        $result = $this->firebaseService->sendToTokens(
            $tokens,
            $payload['title'] ?? 'CreativePOS',
            $payload['body'] ?? '',
            $payload['data'] ?? [],
        );

        if ($event !== null) {
            $this->logService->record(
                event: $event,
                channel: NotificationChannel::Push,
                status: $result['success'] ? 'sent' : 'failed',
                user: $notifiable instanceof \App\Models\User ? $notifiable : null,
                recipient: implode(',', array_slice($tokens, 0, 3)),
                message: ($payload['title'] ?? '').': '.($payload['body'] ?? ''),
                response: $result['response'] ?? ['error' => $result['error'] ?? null],
                dedupKey: method_exists($notification, 'dedupKey') ? $notification->dedupKey() : null,
            );
        }
    }
}