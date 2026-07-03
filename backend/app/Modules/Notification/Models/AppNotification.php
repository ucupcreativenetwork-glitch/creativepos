<?php

namespace App\Modules\Notification\Models;

use App\Models\User;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AppNotification extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $table = 'notifications';

    protected $fillable = [
        'tenant_id',
        'user_id',
        'type',
        'title',
        'body',
        'data',
        'read_at',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'data' => 'array',
            'read_at' => 'datetime',
            'created_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}