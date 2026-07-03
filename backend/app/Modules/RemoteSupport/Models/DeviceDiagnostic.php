<?php

namespace App\Modules\RemoteSupport\Models;

use App\Modules\Auth\Models\UserDevice;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DeviceDiagnostic extends Model
{
    protected $fillable = [
        'user_device_id',
        'type',
        'title',
        'content',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
        ];
    }

    public function device(): BelongsTo
    {
        return $this->belongsTo(UserDevice::class, 'user_device_id');
    }
}