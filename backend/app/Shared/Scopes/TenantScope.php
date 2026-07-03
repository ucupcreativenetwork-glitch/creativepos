<?php

namespace App\Shared\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;

class TenantScope implements Scope
{
    public function apply(Builder $builder, Model $model): void
    {
        $tenantId = tenant('id');

        if ($tenantId === null) {
            if (! app()->runningInConsole()) {
                $builder->whereRaw('1 = 0');
            }

            return;
        }

        $builder->where($model->getTable().'.tenant_id', $tenantId);
    }
}