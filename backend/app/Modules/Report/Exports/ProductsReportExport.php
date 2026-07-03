<?php

namespace App\Modules\Report\Exports;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class ProductsReportExport implements FromCollection, ShouldAutoSize, WithHeadings, WithStyles, WithTitle
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
        return collect($this->rows)->values()->map(function (array $row, int $index) {
            return [
                $index + 1,
                $row['product_name'],
                $row['sku'] ?? '-',
                (float) $row['total_qty'],
                (float) $row['total_revenue'],
            ];
        });
    }

    /**
     * @return list<string>
     */
    public function headings(): array
    {
        return [
            'Rank',
            'Produk',
            'SKU',
            'Qty Terjual',
            'Revenue (Rp)',
        ];
    }

    public function title(): string
    {
        return 'Produk Terlaris';
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
            'title' => 'Laporan Produk Terlaris',
            'date_from' => $this->dateFrom,
            'date_to' => $this->dateTo,
            'headings' => $this->headings(),
            'rows' => $this->rows,
        ];
    }
}