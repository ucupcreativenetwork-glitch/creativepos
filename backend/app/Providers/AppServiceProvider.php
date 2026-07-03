<?php

namespace App\Providers;

use App\Models\User;
use App\Modules\Notification\Services\MailConfigService;
use App\Shared\Support\FrontendUrl;
use App\Modules\Inventory\Models\Product;
use App\Modules\Loyalty\Models\Member;
use App\Modules\Tenant\Models\Outlet;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Notifications\Events\NotificationSending;
use Illuminate\Support\Facades\Event;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        ResetPassword::createUrlUsing(function (object $notifiable, string $token): string {
            return FrontendUrl::resetPassword($token, $notifiable->getEmailForPasswordReset());
        });

        RateLimiter::for('api', function (Request $request) {
            return $request->user()
                ? Limit::perMinute(60)->by($request->user()->id)
                : Limit::perMinute(20)->by($request->ip());
        });

        RateLimiter::for('auth', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip());
        });

        Route::bind('outlet', function (string $value): Outlet {
            return Outlet::query()
                ->where('uuid', $value)
                ->when(is_numeric($value), fn ($q) => $q->orWhere('id', (int) $value))
                ->firstOrFail();
        });

        Route::bind('product', function (string $value): Product {
            $query = Product::query();

            if (is_numeric($value)) {
                return $query->where('id', (int) $value)->firstOrFail();
            }

            return $query->where('uuid', $value)->firstOrFail();
        });

        Route::bind('member', function (string $value): Member {
            $query = Member::query();

            if (is_numeric($value)) {
                return $query->where('id', (int) $value)->firstOrFail();
            }

            return $query->where('uuid', $value)->firstOrFail();
        });

        Event::listen(NotificationSending::class, function (NotificationSending $event): void {
            if ($event->channel !== 'mail') {
                return;
            }

            $notifiable = $event->notifiable;
            $tenantId = is_object($notifiable) && isset($notifiable->tenant_id)
                ? $notifiable->tenant_id
                : tenant('id');

            if ($tenantId) {
                app(MailConfigService::class)->applyForTenant((int) $tenantId);
            }
        });
    }
}