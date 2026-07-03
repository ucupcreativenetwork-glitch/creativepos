<?php

namespace App\Modules\Notification\Services;

use App\Models\User;
use App\Modules\Notification\Enums\NotificationChannel;
use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Models\NotificationLog;

class NotificationLogService
{
    /**
     * @param  array<string, mixed>|null  $response
     */
    public function record(
        NotificationEvent $event,
        NotificationChannel $channel,
        string $status,
        ?User $user = null,
        ?string $recipient = null,
        ?string $message = null,
        ?array $response = null,
        ?string $dedupKey = null,
    ): void {
        NotificationLog::query()->create([
            'tenant_id' => tenant('id'),
            'user_id' => $user?->id,
            'event' => $event->value,
            'channel' => $channel->value,
            'recipient' => $recipient,
            'status' => $status,
            'dedup_key' => $dedupKey,
            'message' => $message,
            'response' => $response,
            'created_at' => now(),
        ]);
    }
}