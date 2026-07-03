<?php

/**
 * Import produk massal dari CSV ke tenant.
 *
 * Format CSV (header wajib):
 *   name,sku,base_price,cost_price,barcode,category_name,initial_stock,min_stock,track_stock
 *
 * Usage:
 *   docker compose -f docker-compose.client.yml exec -T backend \
 *     php scripts/import-products-csv.php /var/www/html/storage/app/import/products.csv 1
 */

use App\Modules\Inventory\Services\ProductImportService;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Http\UploadedFile;

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$csvPath = $argv[1] ?? '';
$tenantId = isset($argv[2]) ? (int) $argv[2] : null;

if ($csvPath === '' || ! is_readable($csvPath)) {
    fwrite(STDERR, "Usage: php scripts/import-products-csv.php <path-csv> [tenant_id]\n");
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

$service = app(ProductImportService::class);
$result = $service->importFromFile($uploadedFile);

echo "Import selesai untuk tenant #{$tenant->id} ({$tenant->name})\n";
echo "Berhasil : {$result['created']}\n";
echo "Dilewati : {$result['skipped']}\n";

if ($result['errors'] !== []) {
    echo "\nDetail:\n";
    foreach ($result['errors'] as $error) {
        echo "  - {$error}\n";
    }
}

exit($result['created'] > 0 ? 0 : 1);