<?php

namespace App\Modules\Auth\Models;

use App\Models\User;
use App\Modules\Platform\Models\Tenant;
use App\Modules\RemoteSupport\Models\DeviceDiagnostic;
use App\Modules\RemoteSupport\Models\DeviceRemoteCommand;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class UserDevice extends Model
{
    protected $fillable = [
        'user_id',
        'tenant_id',
        'device_name',
        'fingerprint',
        'install_id',
        'fcm_token',
        'platform',
        'browser',
        'app_version',
        'build_number',
        'os_version',
        'device_model',
        'mac_address',
        'last_ip',
        'api_base_url',
        'agent_version',
        'is_trusted',
        'remote_agent_enabled',
        'last_used_at',
        'last_seen_at',
    ];

    protected function casts(): array
    {
        return [
            'is_trusted' => 'boolean',
            'remote_agent_enabled' => 'boolean',
            'last_used_at' => 'datetime',
            'last_seen_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function remoteCommands(): HasMany
    {
        return $this->hasMany(DeviceRemoteCommand::class);
    }

    public function diagnostics(): HasMany
    {
        return $this->hasMany(DeviceDiagnostic::class);
    }
}