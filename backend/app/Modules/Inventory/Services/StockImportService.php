<?php

namespace App\Modules\Inventory\Services;

use App\Modules\Inventory\Imports\StockSpreadsheetReader;
use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\Warehouse;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Maatwebsite\Excel\Facades\Excel;

class StockImportService
{
    private const REQUIRED_COLUMNS = ['sku', 'quantity', 'action'];

    public function __construct(
        private readonly StockService $stockService,
    ) {}

    public function importFromFile(
        UploadedFile $file,
        ?int $defaultWarehouseId = null,
        ?int $userId = null,
    ): array {
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
        $defaultWarehouse = $this->resolveDefaultWarehouse($defaultWarehouseId);
        $warehouseCache = [];

        $processed = 0;
        $skipped = 0;
        $errors = [];

        foreach ($rows as $rowNumber => $row) {
            $line = $rowNumber + 2;

            if ($this->isEmptyRow($row)) {
                continue;
            }

            $sku = trim((string) ($row[$index['sku']] ?? ''));
            $action = strtolower(trim((string) ($row[$index['action']] ?? '')));
            $quantityRaw = trim((string) ($row[$index['quantity']] ?? ''));
            $notes = isset($index['notes'])
                ? trim((string) ($row[$index['notes']] ?? ''))
                : null;
            $warehouseCode = isset($index['warehouse_code'])
                ? trim((string) ($row[$index['warehouse_code']] ?? ''))
                : '';

            if ($sku === '') {
                $errors[] = "Baris {$line}: SKU wajib diisi.";
                $skipped++;

                continue;
            }

            if (! in_array($action, ['in', 'out', 'adjustment'], true)) {
                $errors[] = "Baris {$line}: action harus in, out, atau adjustment.";
                $skipped++;

                continue;
            }

            if ($quantityRaw === '' || ! is_numeric($quantityRaw)) {
                $errors[] = "Baris {$line}: quantity tidak valid.";
                $skipped++;

                continue;
            }

            $quantity = (float) $quantityRaw;

            if ($action === 'adjustment') {
                if ($quantity < 0) {
                    $errors[] = "Baris {$line}: stok baru tidak boleh negatif.";
                    $skipped++;

                    continue;
                }
            } elseif ($quantity <= 0) {
                $errors[] = "Baris {$line}: quantity harus lebih dari 0.";
                $skipped++;

                continue;
            }

            $product = Product::query()
                ->where('sku', $sku)
                ->first();

            if ($product === null) {
                $errors[] = "Baris {$line}: produk dengan SKU '{$sku}' tidak ditemukan.";
                $skipped++;

                continue;
            }

            if (! $product->track_stock) {
                $errors[] = "Baris {$line}: produk '{$sku}' tidak melacak stok.";
                $skipped++;

                continue;
            }

            try {
                $warehouse = $this->resolveWarehouse(
                    $warehouseCode,
                    $defaultWarehouse,
                    $warehouseCache,
                );

                DB::transaction(function () use (
                    $product,
                    $warehouse,
                    $action,
                    $quantity,
                    $notes,
                    $userId,
                ): void {
                    if ($action === 'in') {
                        $this->stockService->stockIn(
                            $product->id,
                            $warehouse->id,
                            $quantity,
                            $notes ?: 'Import stok massal',
                            $userId,
                        );
                    } elseif ($action === 'out') {
                        $this->stockService->stockOut(
                            $product->id,
                            $warehouse->id,
                            $quantity,
                            $notes ?: 'Import stok massal',
                            $userId,
                        );
                    } else {
                        $this->stockService->adjustment(
                            $product->id,
                            $warehouse->id,
                            $quantity,
                            $notes ?: 'Import stok massal',
                            $userId,
                        );
                    }
                });

                $processed++;
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
            'processed' => $processed,
            'skipped' => $skipped,
            'errors' => $errors,
        ];
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

    protected function resolveDefaultWarehouse(?int $warehouseId): Warehouse
    {
        if ($warehouseId !== null) {
            return Warehouse::query()
                ->where('id', $warehouseId)
                ->where('is_active', true)
                ->firstOrFail();
        }

        $warehouse = Warehouse::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->first();

        if ($warehouse === null) {
            abort(422, 'Belum ada gudang aktif. Tambahkan outlet/gudang di pengaturan.');
        }

        return $warehouse;
    }

    protected function resolveWarehouse(
        string $warehouseCode,
        Warehouse $defaultWarehouse,
        array &$cache,
    ): Warehouse {
        if ($warehouseCode === '') {
            return $defaultWarehouse;
        }

        if (isset($cache[$warehouseCode])) {
            return $cache[$warehouseCode];
        }

        $warehouse = Warehouse::query()
            ->where('code', $warehouseCode)
            ->where('is_active', true)
            ->first();

        if ($warehouse === null) {
            abort(422, "Gudang dengan kode '{$warehouseCode}' tidak ditemukan.");
        }

        $cache[$warehouseCode] = $warehouse;

        return $warehouse;
    }

    protected function isEmptyRow(array $row): bool
    {
        return count(array_filter($row, static fn ($value) => trim((string) $value) !== '')) === 0;
    }
}