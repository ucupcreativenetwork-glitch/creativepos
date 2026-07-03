<?php

namespace App\Modules\Notification\Listeners;

use App\Modules\Auth\Events\UserLoggedIn;
use App\Modules\Notification\Notifications\LoginNotification;
use App\Modules\Notification\Services\MailConfigService;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Contracts\Queue\ShouldQueue;

class SendLoginNotification implements ShouldQueue
{
    public function handle(UserLoggedIn $event): void
    {
        $user = $event->user;

        if ($user->tenant_id) {
            set_tenant(Tenant::query()->find($user->tenant_id));
        }

        app(MailConfigService::class)->applyForTenant($user->tenant_id);

        $user->notify(new LoginNotification(
            ipAddress: $event->ipAddress,
            deviceName: $event->deviceName,
        ));
    }
}