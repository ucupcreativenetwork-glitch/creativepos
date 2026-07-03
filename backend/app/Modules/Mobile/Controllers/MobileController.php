<?php

namespace App\Modules\Mobile\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Mobile\Models\AppRelease;
use App\Modules\Mobile\Services\AppReleaseService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

class MobileController extends Controller
{
    public function __construct(
        private readonly AppReleaseService $releases,
    ) {}

    public function version(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'platform' => 'sometimes|string|in:android,ios',
            'current_version' => 'required|string|max:20',
            'build_number' => 'required|integer|min:1',
        ]);

        $data = $this->releases->checkUpdate(
            $validated['platform'] ?? 'android',
            $validated['current_version'],
            (int) $validated['build_number'],
        );

        return ApiResponse::success($data);
    }

    public function download(AppRelease $release): BinaryFileResponse
    {
        if (! $release->is_active) {
            abort(404, 'Rilis tidak aktif.');
        }

        $path = $this->releases->downloadPath($release);
        $filename = $release->original_filename
            ?? "creativepos-{$release->version}-{$release->build_number}.apk";

        return response()->download($path, $filename, [
            'Content-Type' => 'application/vnd.android.package-archive',
        ]);
    }
}