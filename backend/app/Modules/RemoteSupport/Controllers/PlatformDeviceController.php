<?php

namespace App\Modules\RemoteSupport\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Models\UserDevice;
use App\Modules\RemoteSupport\Services\DeviceRemoteService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlatformDeviceController extends Controller
{
    public function __construct(
        private readonly DeviceRemoteService $remoteService,
    ) {}

    public function stats(Request $request): JsonResponse
    {
        $this->ensureSuperAdmin($request);

        return ApiResponse::success($this->remoteService->platformStats());
    }

    public function index(Request $request): JsonResponse
    {
        $this->ensureSuperAdmin($request);

        $devices = $this->remoteService->paginatePlatformDevices($request->only([
            'search',
            'platform',
            'tenant_id',
            'online_only',
            'per_page',
        ]));

        return ApiResponse::success(
            collect($devices->items())->map(
                fn (UserDevice $device) => $this->remoteService->formatDevice($device),
            ),
            'Devices retrieved',
            200,
            [
                'current_page' => $devices->currentPage(),
                'per_page' => $devices->perPage(),
                'total' => $devices->total(),
                'last_page' => $devices->lastPage(),
            ],
        );
    }

    public function show(Request $request, UserDevice $device): JsonResponse
    {
        $this->ensureSuperAdmin($request);

        return ApiResponse::success($this->remoteService->getDeviceDetail($device));
    }

    public function queueCommand(Request $request, UserDevice $device): JsonResponse
    {
        $this->ensureSuperAdmin($request);

        $validated = $request->validate([
            'command' => ['required', 'string', 'max:50'],
            'payload' => ['nullable', 'array'],
        ]);

        $command = $this->remoteService->queueCommand(
            $device,
            $validated['command'],
            $validated['payload'] ?? null,
            $request->user(),
        );

        return ApiResponse::success([
            'id' => $command->id,
            'command' => $command->command,
            'status' => $command->status,
        ], 'Perintah remote dikirim ke perangkat');
    }

    protected function ensureSuperAdmin(Request $request): void
    {
        if (! $request->user()?->is_super_admin) {
            abort(403, 'Super admin access required.');
        }
    }
}