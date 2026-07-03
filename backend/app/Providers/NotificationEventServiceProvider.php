<?php

namespace App\Providers;

use App\Modules\Auth\Events\UserLoggedIn;
use App\Modules\Notification\Events\InvoiceDueEvent;
use App\Modules\Notification\Events\LowStockDetectedEvent;
use App\Modules\Notification\Events\OrderCreatedEvent;
use App\Modules\Notification\Listeners\SendInvoiceDueNotification;
use App\Modules\Notification\Listeners\SendLoginNotification;
use App\Modules\Notification\Listeners\SendLowStockNotification;
use App\Modules\Notification\Listeners\SendOrderCreatedNotification;
use App\Modules\Notification\Listeners\SendPasswordResetConfirmation;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class NotificationEventServiceProvider extends ServiceProvider
{
    /**
     * @var array<class-string, list<class-string>>
     */
    protected $listen = [
        InvoiceDueEvent::class => [
            SendInvoiceDueNotification::class,
        ],
        LowStockDetectedEvent::class => [
            SendLowStockNotification::class,
        ],
        OrderCreatedEvent::class => [
            SendOrderCreatedNotification::class,
        ],
        UserLoggedIn::class => [
            SendLoginNotification::class,
        ],
        PasswordReset::class => [
            SendPasswordResetConfirmation::class,
        ],
    ];
}