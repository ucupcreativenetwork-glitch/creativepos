<?php

namespace App\Modules\Mobile\Controllers;

use App\Http\Controllers\Controller;
use App\Modules\Mobile\Models\AppRelease;
use App\Modules\Mobile\Services\AppReleaseService;
use App\Shared\Responses\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AppReleaseAdminController extends Controller
{
    public function __construct(
        private readonly AppReleaseService $releases,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $platform = $request->input('platform', 'android');

        return ApiResponse::success(
            $this->releases->list($platform)->map(fn (AppRelease $r) => $this->format($r))->all(),
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'file' => [
                'required',
                'file',
                'max:153600',
                'mimetypes:application/vnd.android.package-archive,application/octet-stream,application/zip',
            ],
            'version' => 'required|string|max:20',
            'build_number' => 'required|integer|min:1',
            'platform' => 'sometimes|string|in:android,ios',
            'release_notes' => 'nullable|string|max:5000',
            'is_mandatory' => 'sometimes|boolean',
        ]);

        $release = $this->releases->storeRelease(
            $validated,
            $request->file('file'),
        );

        return ApiResponse::created($this->format($release), 'Rilis aplikasi berhasil diunggah.');
    }

    public function activate(AppRelease $release): JsonResponse
    {
        $release = $this->releases->activate($release);

        return ApiResponse::success($this->format($release), 'Rilis diaktifkan.');
    }

    public function destroy(AppRelease $release): JsonResponse
    {
        $this->releases->delete($release);

        return ApiResponse::success(null, 'Rilis dihapus.');
    }

    protected function format(AppRelease $release): array
    {
        return [
            'id' => $release->id,
            'platform' => $release->platform,
            'version' => $release->version,
            'build_number' => $release->build_number,
            'file_size' => $release->file_size,
            'checksum_sha256' => $release->checksum_sha256,
            'release_notes' => $release->release_notes,
            'is_mandatory' => $release->is_mandatory,
            'is_active' => $release->is_active,
            'download_url' => url("/api/v1/mobile/download/{$release->id}"),
            'published_at' => $release->published_at?->toIso8601String(),
            'created_at' => $release->created_at?->toIso8601String(),
        ];
    }
}