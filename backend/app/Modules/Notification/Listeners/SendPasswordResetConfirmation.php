<?php

namespace App\Modules\Notification\Listeners;

use App\Modules\Notification\Notifications\PasswordResetConfirmationNotification;
use App\Modules\Notification\Services\MailConfigService;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Contracts\Queue\ShouldQueue;

class SendPasswordResetConfirmation implements ShouldQueue
{
    public function handle(PasswordReset $event): void
    {
        $user = $event->user;

        if (! $user instanceof \App\Models\User) {
            return;
        }

        if ($user->tenant_id) {
            set_tenant(Tenant::query()->find($user->tenant_id));
        }

        app(MailConfigService::class)->applyForTenant($user->tenant_id);

        $user->notify(new PasswordResetConfirmationNotification);
    }
}