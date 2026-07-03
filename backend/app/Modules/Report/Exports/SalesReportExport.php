<?php

namespace App\Modules\Report\Exports;

use Illuminate\Support\Collection;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\ShouldAutoSize;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithTitle;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class SalesReportExport implements FromCollection, ShouldAutoSize, WithHeadings, WithStyles, WithTitle
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
        $data = collect($this->rows)->map(fn (array $row) => [
            $row['period'],
            (float) $row['revenue'],
            (int) $row['transactions'],
            (float) $row['discount_total'],
            (float) $row['tax_total'],
        ]);

        if ($data->isNotEmpty()) {
            $data->push([
                'TOTAL',
                $data->sum(fn ($row) => $row[1]),
                $data->sum(fn ($row) => $row[2]),
                $data->sum(fn ($row) => $row[3]),
                $data->sum(fn ($row) => $row[4]),
            ]);
        }

        return $data;
    }

    /**
     * @return list<string>
     */
    public function headings(): array
    {
        return [
            'Periode',
            'Revenue (Rp)',
            'Transaksi',
            'Diskon (Rp)',
            'Pajak (Rp)',
        ];
    }

    public function title(): string
    {
        return 'Laporan Penjualan';
    }

    public function styles(Worksheet $sheet): array
    {
        $lastRow = $this->rows === [] ? 1 : count($this->rows) + 2;

        return [
            1 => ['font' => ['bold' => true]],
            $lastRow => ['font' => ['bold' => true]],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function meta(): array
    {
        return [
            'title' => 'Laporan Penjualan',
            'date_from' => $this->dateFrom,
            'date_to' => $this->dateTo,
            'headings' => $this->headings(),
            'rows' => $this->rows,
            'totals' => [
                'revenue' => collect($this->rows)->sum('revenue'),
                'transactions' => collect($this->rows)->sum('transactions'),
                'discount_total' => collect($this->rows)->sum('discount_total'),
                'tax_total' => collect($this->rows)->sum('tax_total'),
            ],
        ];
    }
}