<?php

namespace App\Modules\Notification\Models;

use App\Models\User;
use App\Shared\Traits\BelongsToTenant;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationLog extends Model
{
    use BelongsToTenant;

    public $timestamps = false;

    protected $fillable = [
        'tenant_id',
        'user_id',
        'event',
        'channel',
        'recipient',
        'status',
        'dedup_key',
        'message',
        'response',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'response' => 'array',
            'created_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function recentlySent(string $dedupKey, int $hours = 24): bool
    {
        return self::query()
            ->where('dedup_key', $dedupKey)
            ->where('status', 'sent')
            ->where('created_at', '>=', now()->subHours($hours))
            ->exists();
    }
}