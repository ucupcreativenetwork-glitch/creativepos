<?php

namespace App\Modules\Inventory\Services;

use App\Modules\Inventory\Imports\StockSpreadsheetReader;
use App\Modules\Inventory\Models\Product;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Maatwebsite\Excel\Facades\Excel;

class ProductImportService
{
    private const REQUIRED_COLUMNS = ['name', 'sku', 'base_price'];

    public function __construct(
        private readonly ProductService $productService,
    ) {}

    public function importFromFile(UploadedFile $file, ?int $userId = null): array
    {
        $rows = $this->parseFile($file);

        if ($rows === []) {
            abort(422, 'File kosong atau tidak berisi data.');
        }

        $header = array_map(
            static fn ($value) => strtolower(trim((string) $value)),
            array_shift($rows),
        );

        foreach (self::REQUIRED_COLUMNS as $column) {
            if (! in_array($column, $header, true)) {
                abort(422, "Kolom wajib hilang: {$column}");
            }
        }

        $index = array_flip($header);
        $created = 0;
        $skipped = 0;
        $errors = [];

        foreach ($rows as $rowNumber => $row) {
            $line = $rowNumber + 2;

            if ($this->isEmptyRow($row)) {
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
                $errors[] = "Baris {$line}: name, sku, base_price wajib diisi.";
                $skipped++;

                continue;
            }

            if (! is_numeric($basePrice) || (float) $basePrice < 0) {
                $errors[] = "Baris {$line}: base_price tidak valid.";
                $skipped++;

                continue;
            }

            if (Product::query()->where('sku', $sku)->exists()) {
                $errors[] = "Baris {$line}: SKU {$sku} sudah ada — dilewati.";
                $skipped++;

                continue;
            }

            $categoryId = $this->resolveCategoryId($get('category_name'));

            $costPrice = $get('cost_price');
            $initialStock = $get('initial_stock');
            $minStock = $get('min_stock');
            $trackStock = strtolower((string) ($get('track_stock') ?? '1'));
            $track = ! in_array($trackStock, ['0', 'false', 'no', 'tidak'], true);

            try {
                $this->productService->create([
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
                ], $userId);

                $created++;
            } catch (\Throwable $exception) {
                $message = $exception->getMessage();
                if ($exception instanceof \Symfony\Component\HttpKernel\Exception\HttpException) {
                    $message = $exception->getMessage();
                }

                $errors[] = "Baris {$line} ({$sku}): {$message}";
                $skipped++;
            }
        }

        return [
            'created' => $created,
            'skipped' => $skipped,
            'errors' => $errors,
        ];
    }

    protected function resolveCategoryId(?string $categoryName): ?int
    {
        if ($categoryName === null || $categoryName === '') {
            return null;
        }

        $tenantId = tenant('id');
        $categoryId = DB::table('categories')
            ->where('tenant_id', $tenantId)
            ->where('name', $categoryName)
            ->value('id');

        if ($categoryId !== null) {
            return (int) $categoryId;
        }

        return (int) DB::table('categories')->insertGetId([
            'tenant_id' => $tenantId,
            'uuid' => (string) Str::uuid(),
            'name' => $categoryName,
            'slug' => Str::slug($categoryName),
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    protected function parseFile(UploadedFile $file): array
    {
        $extension = strtolower($file->getClientOriginalExtension());

        if (in_array($extension, ['xlsx', 'xls'], true)) {
            $sheets = Excel::toArray(new StockSpreadsheetReader(), $file);

            return $sheets[0] ?? [];
        }

        $handle = fopen($file->getRealPath(), 'r');
        if ($handle === false) {
            abort(422, 'Gagal membaca file CSV.');
        }

        $rows = [];
        while (($row = fgetcsv($handle)) !== false) {
            $rows[] = $row;
        }

        fclose($handle);

        return $rows;
    }

    protected function isEmptyRow(array $row): bool
    {
        return count(array_filter($row, static fn ($value) => trim((string) $value) !== '')) === 0;
    }
}