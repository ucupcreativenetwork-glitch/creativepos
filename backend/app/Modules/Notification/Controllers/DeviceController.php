<?php

namespace App\Modules\Notification\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Auth\Models\UserDevice;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DeviceController extends Controller
{
    public function registerFcmToken(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'fcm_token' => ['required', 'string', 'max:500'],
            'device_name' => ['nullable', 'string', 'max:100'],
            'fingerprint' => ['nullable', 'string', 'max:255'],
            'platform' => ['nullable', 'string', 'max:50'],
        ]);

        $user = $request->user();
        $fingerprint = $validated['fingerprint']
            ?? 'fcm-'.substr(hash('sha256', $validated['fcm_token']), 0, 32);

        $device = UserDevice::query()->updateOrCreate(
            [
                'user_id' => $user->id,
                'fingerprint' => $fingerprint,
            ],
            [
                'device_name' => $validated['device_name'] ?? 'Mobile App',
                'platform' => $validated['platform'] ?? 'unknown',
                'fcm_token' => $validated['fcm_token'],
                'last_used_at' => now(),
            ],
        );

        return ApiResponse::success([
            'id' => $device->id,
            'fingerprint' => $device->fingerprint,
            'registered' => true,
        ], 'FCM token terdaftar');
    }
}