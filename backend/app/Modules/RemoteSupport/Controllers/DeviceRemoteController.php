<?php

namespace App\Modules\RemoteSupport\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Models\UserDevice;
use App\Modules\RemoteSupport\Models\DeviceRemoteCommand;
use App\Modules\RemoteSupport\Services\DeviceRemoteService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceRemoteController extends Controller
{
    public function __construct(
        private readonly DeviceRemoteService $remoteService,
    ) {}

    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_name' => ['required', 'string', 'max:120'],
            'fingerprint' => ['required', 'string', 'max:255'],
            'install_id' => ['nullable', 'string', 'max:64'],
            'platform' => ['nullable', 'string', 'max:50'],
            'browser' => ['nullable', 'string', 'max:100'],
            'app_version' => ['nullable', 'string', 'max:30'],
            'build_number' => ['nullable', 'integer', 'min:1'],
            'os_version' => ['nullable', 'string', 'max:50'],
            'device_model' => ['nullable', 'string', 'max:120'],
            'mac_address' => ['nullable', 'string', 'max:64'],
            'api_base_url' => ['nullable', 'string', 'max:255'],
            'agent_version' => ['nullable', 'string', 'max:20'],
            'fcm_token' => ['nullable', 'string', 'max:500'],
        ]);

        $device = $this->remoteService->registerDevice(
            $request->user(),
            $validated,
            $request,
        );

        return ApiResponse::success(
            $this->remoteService->formatDevice($device),
            'Remote agent terdaftar',
        );
    }

    public function heartbeat(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fingerprint' => ['required', 'string', 'max:255'],
            'app_version' => ['nullable', 'string', 'max:30'],
            'build_number' => ['nullable', 'integer', 'min:1'],
            'fcm_token' => ['nullable', 'string', 'max:500'],
        ]);

        $device = $this->findOwnedDevice($request, $validated['fingerprint']);
        $device = $this->remoteService->heartbeat($device, $request, $validated);

        return ApiResponse::success([
            'device_id' => $device->id,
            'is_online' => true,
            'server_time' => now()->toIso8601String(),
        ], 'Heartbeat diterima');
    }

    public function pendingCommands(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fingerprint' => ['required', 'string', 'max:255'],
        ]);

        $device = $this->findOwnedDevice($request, $validated['fingerprint']);
        $commands = $this->remoteService->pendingCommands($device);

        $commands->each(fn (DeviceRemoteCommand $command) => $this->remoteService->markCommandExecuting($command));

        return ApiResponse::success($commands->map(fn (DeviceRemoteCommand $command) => [
            'id' => $command->id,
            'command' => $command->command,
            'payload' => $command->payload,
        ]));
    }

    public function completeCommand(Request $request, DeviceRemoteCommand $command): JsonResponse
    {
        $validated = $request->validate([
            'fingerprint' => ['required', 'string', 'max:255'],
            'status' => ['required', 'in:completed,failed'],
            'result' => ['nullable', 'string', 'max:50000'],
        ]);

        $device = $this->findOwnedDevice($request, $validated['fingerprint']);

        if ($command->user_device_id !== $device->id) {
            abort(404);
        }

        $updated = $this->remoteService->completeCommand(
            $command,
            $validated['status'],
            $validated['result'] ?? null,
        );

        return ApiResponse::success([
            'id' => $updated->id,
            'status' => $updated->status,
        ], 'Status perintah diperbarui');
    }

    public function uploadDiagnostics(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fingerprint' => ['required', 'string', 'max:255'],
            'type' => ['required', 'string', 'max:30'],
            'title' => ['nullable', 'string', 'max:150'],
            'content' => ['required', 'string', 'max:100000'],
            'metadata' => ['nullable', 'array'],
        ]);

        $device = $this->findOwnedDevice($request, $validated['fingerprint']);
        $diagnostic = $this->remoteService->storeDiagnostic($device, $validated);

        return ApiResponse::success([
            'id' => $diagnostic->id,
            'type' => $diagnostic->type,
            'created_at' => $diagnostic->created_at?->toIso8601String(),
        ], 'Diagnostik diterima');
    }

    protected function findOwnedDevice(Request $request, string $fingerprint): UserDevice
    {
        return UserDevice::query()
            ->where('user_id', $request->user()->id)
            ->where('fingerprint', $fingerprint)
            ->firstOrFail();
    }
}