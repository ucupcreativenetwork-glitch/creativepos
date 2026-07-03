<?php

namespace App\Modules\CRM\Models;

use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;

class Faq extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'question',
        'answer',
        'sort_order',
        'is_active',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'sort_order' => 'integer',
            'is_active' => 'boolean',
            'created_at' => 'datetime',
        ];
    }
}