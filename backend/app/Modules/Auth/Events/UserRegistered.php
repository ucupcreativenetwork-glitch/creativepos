<?php

namespace App\Modules\Auth\Events;

use App\Models\User;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class UserRegistered
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly Tenant $tenant,
        public readonly User $user,
    ) {}
}