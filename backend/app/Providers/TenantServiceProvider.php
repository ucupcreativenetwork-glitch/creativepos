<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class TenantServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton('tenant', fn () => null);
    }

    public function boot(): void
    {
        //
    }
}