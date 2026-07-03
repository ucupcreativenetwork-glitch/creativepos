<?php

namespace App\Modules\Report\Services;

use App\Modules\Report\Exports\InventoryReportExport;
use App\Modules\Report\Exports\ProductsReportExport;
use App\Modules\Report\Exports\SalesReportExport;
use App\Modules\Report\Models\ReportExport;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\Storage;
use Maatwebsite\Excel\Facades\Excel;

class ReportExportGenerator
{
    public function __construct(
        private readonly ReportService $reportService,
    ) {}

    public function generate(ReportExport $export): string
    {
        $filters = $export->filters ?? [];
        $dateFrom = $filters['date_from'] ?? now()->subDays(30)->toDateString();
        $dateTo = $filters['date_to'] ?? now()->toDateString();

        $exportInstance = match ($export->report_type) {
            'sales' => new SalesReportExport(
                $this->reportService->getSalesReport(
                    isset($filters['outlet_id']) ? (int) $filters['outlet_id'] : null,
                    $dateFrom,
                    $dateTo,
                    $filters['type'] ?? 'daily',
                ),
                $dateFrom,
                $dateTo,
            ),
            'products' => new ProductsReportExport(
                $this->reportService->getProductsReport(
                    isset($filters['outlet_id']) ? (int) $filters['outlet_id'] : null,
                    $dateFrom,
                    $dateTo,
                    (int) ($filters['limit'] ?? 100),
                ),
                $dateFrom,
                $dateTo,
            ),
            'inventory' => new InventoryReportExport(
                $this->reportService->getInventoryMovementDetails(
                    isset($filters['outlet_id']) ? (int) $filters['outlet_id'] : null,
                    $dateFrom,
                    $dateTo,
                ),
                $dateFrom,
                $dateTo,
            ),
            default => throw new \InvalidArgumentException("Report type [{$export->report_type}] belum didukung untuk export file."),
        };

        $directory = 'exports/tenant_'.$export->tenant_id;
        $basename = $export->report_type.'_'.$export->uuid;
        $relativePath = $directory.'/'.$basename;

        Storage::disk('local')->makeDirectory($directory);

        return match ($export->format) {
            'xlsx' => $this->storeExcel($exportInstance, $relativePath.'.xlsx'),
            'pdf' => $this->storePdf($export->report_type, $exportInstance->meta(), $relativePath.'.pdf'),
            'csv' => $this->storeCsv($exportInstance, $relativePath.'.csv'),
            default => throw new \InvalidArgumentException("Format [{$export->format}] belum didukung."),
        };
    }

    protected function storeExcel(object $exportInstance, string $path): string
    {
        Excel::store($exportInstance, $path, 'local');

        return $path;
    }

    /**
     * @param  array<string, mixed>  $meta
     */
    protected function storePdf(string $reportType, array $meta, string $path): string
    {
        $pdf = Pdf::loadView('reports.'.$reportType, $meta)
            ->setPaper('a4', 'landscape');

        Storage::disk('local')->put($path, $pdf->output());

        return $path;
    }

    protected function storeCsv(object $exportInstance, string $path): string
    {
        $handle = fopen('php://temp', 'r+');

        if (method_exists($exportInstance, 'headings')) {
            fputcsv($handle, $exportInstance->headings());
        }

        foreach ($exportInstance->collection() as $row) {
            fputcsv($handle, is_array($row) ? $row : $row->toArray());
        }

        rewind($handle);
        $csv = stream_get_contents($handle) ?: '';
        fclose($handle);

        Storage::disk('local')->put($path, $csv);

        return $path;
    }
}