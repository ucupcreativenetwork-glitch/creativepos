<?php

namespace App\Modules\Dashboard\Services;

use App\Modules\Dashboard\Repositories\DashboardRepository;
use Carbon\Carbon;

class DashboardService
{
    public function __construct(
        private readonly DashboardRepository $repository,
    ) {}

    public function getKpi(?int $outletId = null): array
    {
        $now = now();
        $startOfDay = $now->copy()->startOfDay();
        $startOfWeek = $now->copy()->startOfWeek();
        $startOfMonth = $now->copy()->startOfMonth();
        $startOfYear = $now->copy()->startOfYear();

        return [
            'revenue_today' => $this->repository->revenueBetween($outletId, $startOfDay, $now),
            'revenue_week' => $this->repository->revenueBetween($outletId, $startOfWeek, $now),
            'revenue_month' => $this->repository->revenueBetween($outletId, $startOfMonth, $now),
            'revenue_year' => $this->repository->revenueBetween($outletId, $startOfYear, $now),
            'transactions_today' => $this->repository->transactionCountBetween($outletId, $startOfDay, $now),
            'transactions_week' => $this->repository->transactionCountBetween($outletId, $startOfWeek, $now),
            'transactions_month' => $this->repository->transactionCountBetween($outletId, $startOfMonth, $now),
            'new_members_today' => $this->repository->newMembersBetween($outletId, $startOfDay, $now),
            'new_members_month' => $this->repository->newMembersBetween($outletId, $startOfMonth, $now),
            'active_reservations' => $this->repository->activeReservationsCount(),
            'active_deliveries' => $this->repository->activeDeliveriesCount(),
            'open_tickets' => $this->repository->openTicketsCount(),
            'stock_alerts' => $this->repository->lowStockCount(),
            'raw_material_alerts' => $this->repository->rawMaterialAlertCount(),
        ];
    }

    public function getSalesChart(?int $outletId, ?string $dateFrom, ?string $dateTo, string $period = 'daily'): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, $period === 'monthly' ? 365 : 30);

        return $this->repository->salesChartData($outletId, $from, $to, $period)
            ->map(fn ($row) => [
                'label' => $row->label,
                'revenue' => (float) $row->revenue,
                'transactions' => (int) $row->transactions,
            ])
            ->values()
            ->all();
    }

    public function getProductPerformance(?int $outletId, ?string $dateFrom, ?string $dateTo, int $limit = 10): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->topProducts($outletId, $from, $to, $limit)
            ->map(fn ($row) => [
                'product_id' => (int) $row->product_id,
                'product_name' => $row->product_name,
                'total_qty' => (float) $row->total_qty,
                'total_revenue' => (float) $row->total_revenue,
            ])
            ->values()
            ->all();
    }

    public function getCustomerGrowth(?int $outletId, ?string $dateFrom, ?string $dateTo): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->memberGrowthChart($from, $to)
            ->map(fn ($row) => [
                'label' => $row->label,
                'count' => (int) $row->count,
            ])
            ->values()
            ->all();
    }

    public function getOutletPerformance(?string $dateFrom, ?string $dateTo): array
    {
        [$from, $to] = $this->resolveDateRange($dateFrom, $dateTo, 30);

        return $this->repository->outletPerformance($from, $to)
            ->map(fn ($row) => [
                'outlet_id' => (int) $row->id,
                'name' => $row->name,
                'code' => $row->code,
                'revenue' => (float) $row->revenue,
                'transactions' => (int) $row->transactions,
            ])
            ->values()
            ->all();
    }

    public function getLiveFeed(?int $outletId, int $limit = 10): array
    {
        return $this->repository->recentTransactions($outletId, $limit)
            ->map(fn ($tx) => [
                'id' => $tx->id,
                'uuid' => $tx->uuid,
                'transaction_number' => $tx->transaction_number,
                'outlet' => $tx->outlet?->name,
                'cashier' => $tx->cashier?->name,
                'grand_total' => (float) $tx->grand_total,
                'order_type' => $tx->order_type,
                'completed_at' => $tx->completed_at?->toIso8601String(),
                'created_at' => $tx->created_at?->toIso8601String(),
            ])
            ->values()
            ->all();
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