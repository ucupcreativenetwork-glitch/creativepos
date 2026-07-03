<?php

namespace App\Modules\RemoteSupport\Models;

use App\Models\User;
use App\Modules\Auth\Models\UserDevice;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeviceRemoteCommand extends Model
{
    public const STATUS_PENDING = 'pending';

    public const STATUS_EXECUTING = 'executing';

    public const STATUS_COMPLETED = 'completed';

    public const STATUS_FAILED = 'failed';

    public const STATUS_CANCELLED = 'cancelled';

    protected $fillable = [
        'user_device_id',
        'created_by',
        'command',
        'payload',
        'status',
        'result',
        'sent_at',
        'completed_at',
    ];

    protected function casts(): array
    {
        return [
            'payload' => 'array',
            'sent_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(UserDevice::class, 'user_device_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}