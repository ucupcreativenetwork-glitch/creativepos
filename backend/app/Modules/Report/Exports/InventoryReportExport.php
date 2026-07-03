<?php

namespace App\Modules\Report\Exports;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class InventoryReportExport implements FromCollection, ShouldAutoSize, WithHeadings, WithStyles, WithTitle
{
    /**
     * @param  list<array<string, mixed>>  $rows
     */
    public function __construct(
        private readonly array $rows,
        private readonly string $dateFrom,
        private readonly string $dateTo,
    ) {}

    public function collection(): Collection
    {
        return collect($this->rows)->map(fn (array $row) => [
            $row['created_at'],
            $row['product_name'],
            $row['sku'] ?? '-',
            $row['warehouse_name'] ?? '-',
            $row['type'],
            (float) $row['quantity'],
            (float) $row['before_quantity'],
            (float) $row['after_quantity'],
            $row['notes'] ?? '',
        ]);
    }

    /**
     * @return list<string>
     */
    public function headings(): array
    {
        return [
            'Tanggal',
            'Produk',
            'SKU',
            'Gudang',
            'Tipe',
            'Qty',
            'Stok Sebelum',
            'Stok Sesudah',
            'Catatan',
        ];
    }

    public function title(): string
    {
        return 'Pergerakan Stok';
    }

    public function styles(Worksheet $sheet): array
    {
        return [
            1 => ['font' => ['bold' => true]],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function meta(): array
    {
        return [
            'title' => 'Laporan Pergerakan Stok',
            'date_from' => $this->dateFrom,
            'date_to' => $this->dateTo,
            'headings' => $this->headings(),
            'rows' => $this->rows,
        ];
    }
}