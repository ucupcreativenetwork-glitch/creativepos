<?php

/**
 * Publish APK ke server — tanpa login Platform Admin.
 *
 * Usage:
 *   php scripts/publish-apk.php "D:\pos\flutter_app\dist\creativepos-1.1.0-2-release.apk" 1.1.0 2
 */

use App\Modules\Mobile\Models\AppRelease;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$apkPath = $argv[1] ?? null;
$version = $argv[2] ?? '1.1.0';
$buildNumber = (int) ($argv[3] ?? 2);
$notes = $argv[4] ?? 'Update otomatis CreativePOS';
$mandatory = ($argv[5] ?? '0') === '1';

if ($apkPath === null || ! is_file($apkPath)) {
    fwrite(STDERR, "Usage: php scripts/publish-apk.php <path-to-apk> [version] [build_number] [notes] [mandatory:0|1]\n");
    exit(1);
}

$contents = file_get_contents($apkPath);
$platform = 'android';
$filename = Str::uuid().'.apk';
$storagePath = "uploads/platform/releases/{$platform}/{$filename}";

Storage::disk('public')->put($storagePath, $contents);

AppRelease::query()
    ->where('platform', $platform)
    ->where('is_active', true)
    ->update(['is_active' => false]);

$release = AppRelease::query()->updateOrCreate(
    ['platform' => $platform, 'build_number' => $buildNumber],
    [
        'version' => $version,
        'apk_path' => $storagePath,
        'original_filename' => basename($apkPath),
        'file_size' => filesize($apkPath),
        'checksum_sha256' => hash('sha256', $contents),
        'release_notes' => $notes,
        'is_mandatory' => $mandatory,
        'is_active' => true,
        'published_at' => now(),
    ],
);

$baseUrl = rtrim(config('app.url'), '/');

echo "OK — Rilis aktif\n";
echo "Version : {$release->version}\n";
echo "Build   : {$release->build_number}\n";
echo "Download: {$baseUrl}/api/v1/mobile/download/{$release->id}\n";
echo "Check   : {$baseUrl}/api/v1/mobile/version?platform=android&current_version=1.0.0&build_number=1\n";