<?php

namespace App\Shared\Rules;

use Illuminate\Validation\Rule;

final class TenantRule
{
    /**
     * @param  callable(\Illuminate\Database\Query\Builder): void|null  $extra
     */
    public static function exists(string $table, string $column = 'id', ?callable $extra = null): \Illuminate\Validation\Rules\Exists
    {
        $tenantId = tenant('id');

        return Rule::exists($table, $column)->where(function ($query) use ($tenantId, $extra): void {
            $query->where('tenant_id', $tenantId);
            if ($extra !== null) {
                $extra($query);
            }
        });
    }
}