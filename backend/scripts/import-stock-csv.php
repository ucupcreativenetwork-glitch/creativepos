<?php

/**
 * Import pergerakan stok massal dari CSV ke tenant.
 *
 * Format CSV (header wajib):
 *   sku,quantity,action,notes,warehouse_code
 *
 * action: in | out | adjustment
 *   - in/out: quantity = jumlah yang ditambah/dikurangi
 *   - adjustment: quantity = stok baru (bukan selisih)
 *
 * Usage:
 *   docker compose -f docker-compose.client.yml exec -T backend \
 *     php scripts/import-stock-csv.php /var/www/html/storage/app/import/stock.csv 1
 *
 * Argumen:
 *   1 = path CSV (di dalam container backend)
 *   2 = tenant_id (opsional, default: tenant pertama)
 *   3 = warehouse_id default (opsional)
 */

use App\Modules\Inventory\Services\StockImportService;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Http\UploadedFile;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$csvPath = $argv[1] ?? '';
$tenantId = isset($argv[2]) ? (int) $argv[2] : null;
$warehouseId = isset($argv[3]) ? (int) $argv[3] : null;

if ($csvPath === '' || ! is_readable($csvPath)) {
    fwrite(STDERR, "Usage: php scripts/import-stock-csv.php <path-csv> [tenant_id] [warehouse_id]\n");
    fwrite(STDERR, "File tidak ditemukan atau tidak bisa dibaca: {$csvPath}\n");
    exit(1);
}

$tenant = $tenantId
    ? Tenant::query()->find($tenantId)
    : Tenant::query()->orderBy('id')->first();

if ($tenant === null) {
    fwrite(STDERR, "Tenant tidak ditemukan. Daftar bisnis dulu via /register.\n");
    exit(1);
}

set_tenant($tenant);

$uploadedFile = new UploadedFile(
    $csvPath,
    basename($csvPath),
    mime_content_type($csvPath) ?: 'text/csv',
    null,
    true,
);

$service = app(StockImportService::class);
$result = $service->importFromFile($uploadedFile, $warehouseId);

echo "Import stok selesai untuk tenant #{$tenant->id} ({$tenant->name})\n";
echo "Berhasil : {$result['processed']}\n";
echo "Dilewati : {$result['skipped']}\n";

if ($result['errors'] !== []) {
    echo "\nDetail error:\n";
    foreach ($result['errors'] as $error) {
        echo "  - {$error}\n";
    }
}

exit($result['processed'] > 0 ? 0 : 1);