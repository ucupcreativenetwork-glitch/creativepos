<?php

namespace App\Modules\Notification\Services;

use App\Models\User;
use App\Modules\Notification\Models\AppNotification;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class NotificationService
{
    public function __construct(
        private readonly NotificationPreferenceService $preferenceService,
    ) {}

    public function listForUser(User $user, int $perPage = 20): LengthAwarePaginator
    {
        return AppNotification::query()
            ->where('user_id', $user->id)
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function unreadCount(User $user): int
    {
        return AppNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->count();
    }

    public function markAsRead(User $user, int $notificationId): AppNotification
    {
        $notification = AppNotification::query()
            ->where('user_id', $user->id)
            ->findOrFail($notificationId);

        if ($notification->read_at === null) {
            $notification->update(['read_at' => now()]);
        }

        return $notification->fresh();
    }

    public function markAllAsRead(User $user): int
    {
        return AppNotification::query()
            ->where('user_id', $user->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function getPreferences(User $user): array
    {
        return $this->preferenceService->listForUser($user);
    }

    /**
     * @param  list<array{event: string, channel: string, is_enabled: bool}>  $preferences
     */
    public function updatePreferences(User $user, array $preferences): void
    {
        $this->preferenceService->updateForUser($user, $preferences);
    }
}