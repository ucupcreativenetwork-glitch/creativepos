<?php

namespace App\Modules\Tenant\Models;

use App\Shared\Traits\BelongsToTenant;
use App\Shared\Traits\HasUuid;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Outlet extends Model
{
    use BelongsToTenant;
    use HasUuid;
    use SoftDeletes;

    protected $fillable = [
        'tenant_id',
        'uuid',
        'name',
        'code',
        'slug',
        'address',
        'phone',
        'is_active',
        'is_default',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'is_default' => 'boolean',
        ];
    }
}