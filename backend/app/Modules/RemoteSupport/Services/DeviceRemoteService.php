<?php

namespace App\Modules\RemoteSupport\Services;

use App\Models\User;
use App\Modules\Auth\Models\UserDevice;
use App\Modules\RemoteSupport\Models\DeviceDiagnostic;
use App\Modules\RemoteSupport\Models\DeviceRemoteCommand;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

class DeviceRemoteService
{
    public const ONLINE_THRESHOLD_MINUTES = 5;

    public const ALLOWED_COMMANDS = [
        'ping',
        'collect_info',
        'collect_logs',
        'check_update',
        'clear_cache',
        'force_sync',
        'open_remote_assist',
    ];

    public function registerDevice(User $user, array $data, Request $request): UserDevice
    {
        $fingerprint = $data['fingerprint'] ?? $request->header('X-Device-Fingerprint', $request->ip());

        $device = UserDevice::query()->updateOrCreate(
            [
                'user_id' => $user->id,
                'fingerprint' => $fingerprint,
            ],
            [
                'tenant_id' => $user->tenant_id,
                'install_id' => $data['install_id'] ?? null,
                'device_name' => $data['device_name'] ?? 'Unknown Device',
                'platform' => $data['platform'] ?? $request->header('X-Platform'),
                'browser' => $data['browser'] ?? $request->header('X-Browser'),
                'app_version' => $data['app_version'] ?? null,
                'build_number' => $data['build_number'] ?? null,
                'os_version' => $data['os_version'] ?? null,
                'device_model' => $data['device_model'] ?? null,
                'mac_address' => $data['mac_address'] ?? null,
                'last_ip' => $request->ip(),
                'api_base_url' => $data['api_base_url'] ?? null,
                'agent_version' => $data['agent_version'] ?? '1.0.0',
                'fcm_token' => $data['fcm_token'] ?? null,
                'remote_agent_enabled' => true,
                'last_used_at' => now(),
                'last_seen_at' => now(),
            ],
        );

        return $device->fresh();
    }

    public function heartbeat(UserDevice $device, Request $request, array $data = []): UserDevice
    {
        $device->update([
            'last_ip' => $request->ip(),
            'last_seen_at' => now(),
            'last_used_at' => now(),
            'app_version' => $data['app_version'] ?? $device->app_version,
            'build_number' => $data['build_number'] ?? $device->build_number,
            'fcm_token' => $data['fcm_token'] ?? $device->fcm_token,
        ]);

        return $device->fresh();
    }

    public function storeDiagnostic(UserDevice $device, array $data): DeviceDiagnostic
    {
        return DeviceDiagnostic::query()->create([
            'user_device_id' => $device->id,
            'type' => $data['type'],
            'title' => $data['title'] ?? null,
            'content' => $data['content'],
            'metadata' => $data['metadata'] ?? null,
        ]);
    }

    public function pendingCommands(UserDevice $device): Collection
    {
        return DeviceRemoteCommand::query()
            ->where('user_device_id', $device->id)
            ->where('status', DeviceRemoteCommand::STATUS_PENDING)
            ->orderBy('id')
            ->get();
    }

    public function markCommandExecuting(DeviceRemoteCommand $command): DeviceRemoteCommand
    {
        $command->update([
            'status' => DeviceRemoteCommand::STATUS_EXECUTING,
            'sent_at' => now(),
        ]);

        return $command->fresh();
    }

    public function completeCommand(DeviceRemoteCommand $command, string $status, ?string $result = null): DeviceRemoteCommand
    {
        $command->update([
            'status' => $status,
            'result' => $result,
            'completed_at' => now(),
        ]);

        return $command->fresh();
    }

    public function queueCommand(UserDevice $device, string $command, ?array $payload, ?User $admin): DeviceRemoteCommand
    {
        if (! in_array($command, self::ALLOWED_COMMANDS, true)) {
            abort(422, 'Perintah remote tidak dikenal.');
        }

        return DeviceRemoteCommand::query()->create([
            'user_device_id' => $device->id,
            'created_by' => $admin?->id,
            'command' => $command,
            'payload' => $payload,
            'status' => DeviceRemoteCommand::STATUS_PENDING,
        ]);
    }

    public function paginatePlatformDevices(array $filters = []): LengthAwarePaginator
    {
        $query = UserDevice::query()
            ->with(['user:id,name,email,tenant_id', 'user.tenant:id,name,slug'])
            ->orderByDesc('last_seen_at');

        if (! empty($filters['platform'])) {
            $query->where('platform', $filters['platform']);
        }

        if (! empty($filters['tenant_id'])) {
            $query->where('tenant_id', $filters['tenant_id']);
        }

        if (! empty($filters['search'])) {
            $search = $filters['search'];
            $query->where(function ($q) use ($search): void {
                $q->where('device_name', 'like', "%{$search}%")
                    ->orWhere('device_model', 'like', "%{$search}%")
                    ->orWhere('last_ip', 'like', "%{$search}%")
                    ->orWhere('mac_address', 'like', "%{$search}%")
                    ->orWhere('fingerprint', 'like', "%{$search}%")
                    ->orWhereHas('user', fn ($u) => $u
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%"));
            });
        }

        if (($filters['online_only'] ?? false) === true) {
            $query->where('last_seen_at', '>=', now()->subMinutes(self::ONLINE_THRESHOLD_MINUTES));
        }

        return $query->paginate($filters['per_page'] ?? 25);
    }

    public function getDeviceDetail(UserDevice $device): array
    {
        $device->load(['user.tenant']);

        return [
            'device' => $this->formatDevice($device),
            'diagnostics' => $device->diagnostics()
                ->latest()
                ->limit(20)
                ->get()
                ->map(fn (DeviceDiagnostic $d) => [
                    'id' => $d->id,
                    'type' => $d->type,
                    'title' => $d->title,
                    'content' => $d->content,
                    'metadata' => $d->metadata,
                    'created_at' => $d->created_at?->toIso8601String(),
                ]),
            'commands' => $device->remoteCommands()
                ->latest()
                ->limit(20)
                ->get()
                ->map(fn (DeviceRemoteCommand $c) => [
                    'id' => $c->id,
                    'command' => $c->command,
                    'status' => $c->status,
                    'payload' => $c->payload,
                    'result' => $c->result,
                    'created_at' => $c->created_at?->toIso8601String(),
                    'completed_at' => $c->completed_at?->toIso8601String(),
                ]),
        ];
    }

    public function platformStats(): array
    {
        $onlineSince = now()->subMinutes(self::ONLINE_THRESHOLD_MINUTES);

        return [
            'total_devices' => UserDevice::query()->count(),
            'online_devices' => UserDevice::query()->where('last_seen_at', '>=', $onlineSince)->count(),
            'android_devices' => UserDevice::query()->where('platform', 'android')->count(),
            'web_devices' => UserDevice::query()->where('platform', 'web')->count(),
            'pending_commands' => DeviceRemoteCommand::query()
                ->where('status', DeviceRemoteCommand::STATUS_PENDING)
                ->count(),
        ];
    }

    public function formatDevice(UserDevice $device): array
    {
        return [
            'id' => $device->id,
            'device_name' => $device->device_name,
            'fingerprint' => $device->fingerprint,
            'install_id' => $device->install_id,
            'platform' => $device->platform,
            'browser' => $device->browser,
            'app_version' => $device->app_version,
            'build_number' => $device->build_number,
            'os_version' => $device->os_version,
            'device_model' => $device->device_model,
            'mac_address' => $device->mac_address,
            'last_ip' => $device->last_ip,
            'api_base_url' => $device->api_base_url,
            'agent_version' => $device->agent_version,
            'remote_agent_enabled' => (bool) $device->remote_agent_enabled,
            'is_online' => $this->isOnline($device),
            'last_seen_at' => $device->last_seen_at?->toIso8601String(),
            'last_used_at' => $device->last_used_at?->toIso8601String(),
            'created_at' => $device->created_at?->toIso8601String(),
            'user' => $device->user ? [
                'id' => $device->user->id,
                'name' => $device->user->name,
                'email' => $device->user->email,
            ] : null,
            'tenant' => $device->user?->tenant ? [
                'id' => $device->user->tenant->id,
                'name' => $device->user->tenant->name,
                'slug' => $device->user->tenant->slug,
            ] : null,
        ];
    }

    public function isOnline(UserDevice $device): bool
    {
        if (! $device->last_seen_at instanceof Carbon) {
            return false;
        }

        return $device->last_seen_at->greaterThanOrEqualTo(
            now()->subMinutes(self::ONLINE_THRESHOLD_MINUTES),
        );
    }
}