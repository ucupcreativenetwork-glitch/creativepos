<?php

namespace App\Modules\Mobile\Services;

use App\Modules\Mobile\Models\AppRelease;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AppReleaseService
{
    public function latestActive(string $platform = 'android'): ?AppRelease
    {
        return AppRelease::query()
            ->where('platform', $platform)
            ->where('is_active', true)
            ->orderByDesc('build_number')
            ->first();
    }

    public function list(string $platform = 'android')
    {
        return AppRelease::query()
            ->where('platform', $platform)
            ->orderByDesc('build_number')
            ->get();
    }

    public function checkUpdate(
        string $platform,
        string $currentVersion,
        int $currentBuild,
    ): array {
        $latest = $this->latestActive($platform);

        if ($latest === null) {
            return [
                'update_available' => false,
                'current_version' => $currentVersion,
                'current_build_number' => $currentBuild,
            ];
        }

        $updateAvailable = $latest->build_number > $currentBuild;

        return [
            'update_available' => $updateAvailable,
            'current_version' => $currentVersion,
            'current_build_number' => $currentBuild,
            'latest_version' => $latest->version,
            'latest_build_number' => $latest->build_number,
            'min_supported_build' => $latest->build_number,
            'force_update' => $updateAvailable && $latest->is_mandatory,
            'release_notes' => $latest->release_notes,
            'file_size' => $latest->file_size,
            'checksum_sha256' => $latest->checksum_sha256,
            'download_url' => $updateAvailable
                ? url("/api/v1/mobile/download/{$latest->id}")
                : null,
            'published_at' => $latest->published_at?->toIso8601String(),
        ];
    }

    public function storeRelease(array $data, UploadedFile $apk): AppRelease
    {
        return DB::transaction(function () use ($data, $apk) {
            $platform = $data['platform'] ?? 'android';
            $buildNumber = (int) $data['build_number'];

            if (AppRelease::query()
                ->where('platform', $platform)
                ->where('build_number', $buildNumber)
                ->exists()) {
                abort(422, "Build number {$buildNumber} sudah ada untuk platform {$platform}.");
            }

            $filename = Str::uuid().'.apk';
            $path = "uploads/platform/releases/{$platform}/{$filename}";
            $contents = file_get_contents($apk->getRealPath());
            Storage::disk('public')->put($path, $contents);

            AppRelease::query()
                ->where('platform', $platform)
                ->where('is_active', true)
                ->update(['is_active' => false]);

            return AppRelease::query()->create([
                'platform' => $platform,
                'version' => $data['version'],
                'build_number' => $buildNumber,
                'apk_path' => $path,
                'original_filename' => $apk->getClientOriginalName(),
                'file_size' => $apk->getSize(),
                'checksum_sha256' => hash('sha256', $contents),
                'release_notes' => $data['release_notes'] ?? null,
                'is_mandatory' => (bool) ($data['is_mandatory'] ?? false),
                'is_active' => true,
                'published_at' => now(),
            ]);
        });
    }

    public function activate(AppRelease $release): AppRelease
    {
        return DB::transaction(function () use ($release) {
            AppRelease::query()
                ->where('platform', $release->platform)
                ->where('is_active', true)
                ->update(['is_active' => false]);

            $release->update([
                'is_active' => true,
                'published_at' => now(),
            ]);

            return $release->fresh();
        });
    }

    public function delete(AppRelease $release): void
    {
        if ($release->is_active) {
            abort(422, 'Tidak dapat menghapus rilis yang sedang aktif.');
        }

        Storage::disk('public')->delete($release->apk_path);
        $release->delete();
    }

    public function downloadPath(AppRelease $release): string
    {
        $path = Storage::disk('public')->path($release->apk_path);

        if (! is_file($path)) {
            abort(404, 'File APK tidak ditemukan.');
        }

        return $path;
    }
}