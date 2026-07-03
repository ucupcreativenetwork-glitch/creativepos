<?php

namespace App\Modules\Notification\Services;

use App\Models\User;
use App\Modules\Notification\Channels\FirebaseChannel;
use App\Modules\Notification\Channels\InAppChannel;
use App\Modules\Notification\Channels\WhatsappChannel;
use App\Modules\Notification\Enums\NotificationChannel;
use App\Modules\Notification\Enums\NotificationEvent;
use App\Modules\Notification\Models\UserNotificationPreference;

class NotificationPreferenceService
{
    /**
     * @return list<string|class-string>
     */
    public function channelsFor(User $user, NotificationEvent $event): array
    {
        $channels = [];

        if ($this->isEnabled($user, $event, NotificationChannel::InApp)) {
            $channels[] = InAppChannel::class;
        }

        if ($this->isEnabled($user, $event, NotificationChannel::Email) && filled($user->email)) {
            $channels[] = 'mail';
        }

        if ($this->isEnabled($user, $event, NotificationChannel::Whatsapp) && filled($user->phone)) {
            $channels[] = WhatsappChannel::class;
        }

        if ($this->isEnabled($user, $event, NotificationChannel::Push) && $this->hasFcmToken($user)) {
            $channels[] = FirebaseChannel::class;
        }

        return $channels ?: [InAppChannel::class];
    }

    public function isEnabled(User $user, NotificationEvent $event, NotificationChannel $channel): bool
    {
        $preference = UserNotificationPreference::query()
            ->where('user_id', $user->id)
            ->where('event', $event->value)
            ->where('channel', $channel->value)
            ->first();

        if ($preference === null) {
            return true;
        }

        return $preference->is_enabled;
    }

    /**
     * @return list<array{event: string, channel: string, is_enabled: bool}>
     */
    public function listForUser(User $user): array
    {
        $preferences = UserNotificationPreference::query()
            ->where('user_id', $user->id)
            ->get()
            ->keyBy(fn ($pref) => $pref->event.'|'.$pref->channel);

        $result = [];

        foreach (NotificationEvent::cases() as $event) {
            foreach (NotificationChannel::cases() as $channel) {
                $key = $event->value.'|'.$channel->value;
                $result[] = [
                    'event' => $event->value,
                    'event_label' => $event->label(),
                    'channel' => $channel->value,
                    'is_enabled' => $preferences->has($key)
                        ? (bool) $preferences[$key]->is_enabled
                        : true,
                ];
            }
        }

        return $result;
    }

    /**
     * @param  list<array{event: string, channel: string, is_enabled: bool}>  $preferences
     */
    public function updateForUser(User $user, array $preferences): void
    {
        foreach ($preferences as $pref) {
            UserNotificationPreference::query()->updateOrCreate(
                [
                    'user_id' => $user->id,
                    'event' => $pref['event'],
                    'channel' => $pref['channel'],
                ],
                ['is_enabled' => (bool) $pref['is_enabled']],
            );
        }
    }

    protected function hasFcmToken(User $user): bool
    {
        return $user->devices()->whereNotNull('fcm_token')->exists();
    }
}