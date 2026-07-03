<?php

namespace App\Shared\Scopes;

use Spatie\Permission\DefaultTeamResolver;

class TenantTeamResolver extends DefaultTeamResolver
{
    public function getPermissionsTeamId(): int|string|null
    {
        return tenant('id');
    }
}