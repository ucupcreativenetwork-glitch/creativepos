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
 *
 * Argumen:
 *   1 = path CSV (di dalam container backend)
 *   2 = tenant_id (opsional, default: tenant pertama)
 */

use App\Modules\Inventory\Services\ProductService;
use App\Modules\Platform\Models\Tenant;
use Illuminate\Support\Facades\DB;

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

$handle = fopen($csvPath, 'r');
if ($handle === false) {
    fwrite(STDERR, "Gagal membuka file CSV.\n");
    exit(1);
}

$header = fgetcsv($handle);
if ($header === false) {
    fwrite(STDERR, "CSV kosong.\n");
    exit(1);
}

$header = array_map(static fn ($h) => strtolower(trim((string) $h)), $header);
$required = ['name', 'sku', 'base_price'];
foreach ($required as $col) {
    if (! in_array($col, $header, true)) {
        fwrite(STDERR, "Kolom wajib hilang: {$col}\n");
        fwrite(STDERR, 'Header yang ditemukan: '.implode(', ', $header)."\n";
        exit(1);
    }
}

$index = array_flip($header);
$productService = app(ProductService::class);

$created = 0;
$skipped = 0;
$errors = [];
$rowNum = 1;

while (($row = fgetcsv($handle)) !== false) {
    $rowNum++;

    if (count(array_filter($row, static fn ($v) => trim((string) $v) !== '')) === 0) {
        continue;
    }

    $get = static function (string $key) use ($row, $index): ?string {
        if (! isset($index[$key])) {
            return null;
        }
        $value = $row[$index[$key]] ?? null;

        return $value !== null ? trim((string) $value) : null;
    };

    $name = $get('name');
    $sku = $get('sku');
    $basePrice = $get('base_price');

    if ($name === '' || $sku === '' || $basePrice === '') {
        $errors[] = "Baris {$rowNum}: name, sku, base_price wajib diisi.";
        $skipped++;
        continue;
    }

    if (! is_numeric($basePrice) || (float) $basePrice < 0) {
        $errors[] = "Baris {$rowNum}: base_price tidak valid ({$basePrice}).";
        $skipped++;
        continue;
    }

    $categoryId = null;
    $categoryName = $get('category_name');
    if ($categoryName !== null && $categoryName !== '') {
        $categoryId = DB::table('categories')
            ->where('tenant_id', $tenant->id)
            ->where('name', $categoryName)
            ->value('id');

        if ($categoryId === null) {
            $categoryId = DB::table('categories')->insertGetId([
                'tenant_id' => $tenant->id,
                'uuid' => (string) Illuminate\Support\Str::uuid(),
                'name' => $categoryName,
                'slug' => Illuminate\Support\Str::slug($categoryName),
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    $costPrice = $get('cost_price');
    $initialStock = $get('initial_stock');
    $minStock = $get('min_stock');
    $trackStock = strtolower((string) ($get('track_stock') ?? '1'));
    $track = ! in_array($trackStock, ['0', 'false', 'no', 'tidak'], true);

    try {
        $productService->create([
            'name' => $name,
            'sku' => $sku,
            'barcode' => $get('barcode'),
            'category_id' => $categoryId,
            'base_price' => (float) $basePrice,
            'cost_price' => is_numeric($costPrice) ? (float) $costPrice : null,
            'min_stock' => is_numeric($minStock) ? (int) $minStock : 0,
            'track_stock' => $track,
            'is_active' => true,
            'is_available' => true,
            'show_in_pos' => true,
            'initial_stock' => is_numeric($initialStock) ? (float) $initialStock : 0,
        ]);
        $created++;
    } catch (Throwable $e) {
        $message = $e->getMessage();
        if (str_contains($message, 'Duplicate') || str_contains($message, 'unique')) {
            $errors[] = "Baris {$rowNum}: SKU {$sku} sudah ada — dilewati.";
        } else {
            $errors[] = "Baris {$rowNum}: {$message}";
        }
        $skipped++;
    }
}

fclose($handle);

echo "Import selesai untuk tenant #{$tenant->id} ({$tenant->name})\n";
echo "Berhasil : {$created}\n";
echo "Dilewati : {$skipped}\n";

if ($errors !== []) {
    echo "\nDetail:\n";
    foreach ($errors as $error) {
        echo "  - {$error}\n";
    }
}

exit($created > 0 ? 0 : 1);