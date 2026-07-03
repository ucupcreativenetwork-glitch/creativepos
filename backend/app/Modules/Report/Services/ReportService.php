<?php

namespace App\Modules\Report\Services;

use App\Modules\Report\Jobs\GenerateReportJob;
use App\Modules\Report\Models\ReportExport;
use App\Modules\Report\Repositories\ReportRepository;
use Carbon\Carbon;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;


class ReportService
{
    public function __construct(
        private readonly ReportRepository $repository,
    ) {}

    public function getSalesReport(?int $outletId, ?string $dateFrom, ?string $dateTo, string $type = 'daily'): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->salesReport($outletId, $from, $to, $type)
            ->map(fn ($row) => [
                'period' => $row->period,
                'revenue' => (float) $row->revenue,
                'subtotal' => (float) $row->subtotal,
                'discount_total' => (float) $row->discount_total,
                'tax_total' => (float) $row->tax_total,
                'transactions' => (int) $row->transactions,
            ])
            ->values()
            ->all();
    }

    public function getProductsReport(?int $outletId, ?string $dateFrom, ?string $dateTo, int $limit = 20): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->topProducts($outletId, $from, $to, $limit)
            ->map(fn ($row) => [
                'product_id' => (int) $row->product_id,
                'product_name' => $row->product_name,
                'sku' => $row->sku,
                'total_qty' => (float) $row->total_qty,
                'total_revenue' => (float) $row->total_revenue,
            ])
            ->values()
            ->all();
    }

    public function getInventoryReport(?int $outletId, ?string $dateFrom, ?string $dateTo): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->inventoryMovements($outletId, $from, $to)
            ->map(fn ($row) => [
                'type' => $row->type,
                'movement_count' => (int) $row->movement_count,
                'total_quantity' => (float) $row->total_quantity,
            ])
            ->values()
            ->all();
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function getInventoryMovementDetails(?int $outletId, ?string $dateFrom, ?string $dateTo): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->inventoryMovementDetails($outletId, $from, $to)
            ->map(fn ($movement) => [
                'created_at' => $movement->created_at?->format('Y-m-d H:i'),
                'product_name' => $movement->product?->name ?? '-',
                'sku' => $movement->product?->sku,
                'warehouse_name' => $movement->warehouse?->name,
                'type' => $movement->type,
                'quantity' => (float) $movement->quantity,
                'before_quantity' => (float) $movement->before_quantity,
                'after_quantity' => (float) $movement->after_quantity,
                'notes' => $movement->notes,
            ])
            ->values()
            ->all();
    }

    public function getMembersReport(?string $dateFrom, ?string $dateTo, string $type = 'daily'): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->memberGrowth($from, $to, $type)
            ->map(fn ($row) => [
                'period' => $row->period,
                'new_members' => (int) $row->new_members,
                'active_members' => (int) $row->active_members,
            ])
            ->values()
            ->all();
    }

    public function getProfitLossReport(?int $outletId, ?string $dateFrom, ?string $dateTo): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->profitLoss($outletId, $from, $to);
    }

    public function getCashFlowReport(?int $outletId, ?string $dateFrom, ?string $dateTo): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->cashFlow($outletId, $from, $to)
            ->map(fn ($row) => [
                'payment_method' => $row->payment_method,
                'payment_method_name' => $row->payment_method_name,
                'payment_type' => $row->payment_type,
                'total_amount' => (float) $row->total_amount,
                'payment_count' => (int) $row->payment_count,
            ])
            ->values()
            ->all();
    }

    public function createExport(string $reportType, string $format, array $filters, ?int $userId): ReportExport
    {
        $export = ReportExport::query()->create([
            'report_type' => $reportType,
            'format' => $format,
            'status' => 'pending',
            'filters' => $filters,
            'created_by' => $userId,
            'created_at' => now(),
        ]);

        GenerateReportJob::dispatch($export->id);

        return $export->fresh();
    }

    public function listExports(int $perPage = 15): LengthAwarePaginator
    {
        return ReportExport::query()
            ->orderByDesc('created_at')
            ->paginate($perPage);
    }

    public function findExportByUuid(string $uuid): ?ReportExport
    {
        return ReportExport::query()->where('uuid', $uuid)->first();
    }

    protected function resolveDateRange(?string $dateFrom, ?string $dateTo, int $defaultDays): array
    {
        $to = $dateTo ? Carbon::parse($dateTo)->endOfDay() : now();
        $from = $dateFrom
            ? Carbon::parse($dateFrom)->startOfDay()
            : $to->copy()->subDays($defaultDays)->startOfDay();

        return [$from, $to];
    }
}