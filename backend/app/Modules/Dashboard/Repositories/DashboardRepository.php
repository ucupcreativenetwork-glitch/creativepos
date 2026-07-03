<?php

namespace App\Modules\Dashboard\Repositories;

use App\Modules\Inventory\Models\Product;
use App\Modules\Inventory\Models\RawMaterial;
use App\Modules\Loyalty\Models\Member;
use App\Modules\POS\Models\SaleTransaction;
use App\Modules\POS\Models\SaleTransactionItem;
use App\Modules\Tenant\Models\Outlet;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class DashboardRepository
{
    public function revenueBetween(?int $outletId, Carbon $from, Carbon $to): float
    {
        return (float) SaleTransaction::query()
            ->completed()
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->whereBetween('created_at', [$from, $to])
            ->sum('grand_total');
    }

    public function transactionCountBetween(?int $outletId, Carbon $from, Carbon $to): int
    {
        return SaleTransaction::query()
            ->completed()
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->whereBetween('created_at', [$from, $to])
            ->count();
    }

    public function newMembersBetween(?int $outletId, Carbon $from, Carbon $to): int
    {
        return Member::query()
            ->whereBetween('created_at', [$from, $to])
            ->count();
    }

    public function lowStockCount(): int
    {
        return Product::query()
            ->where('track_stock', true)
            ->where('is_active', true)
            ->whereHas('stocks', function ($q) {
                $q->whereColumn('product_stocks.quantity', '<=', 'products.min_stock');
            })
            ->count();
    }

    public function rawMaterialAlertCount(): int
    {
        if (! $this->tableExists('raw_materials')) {
            return 0;
        }

        return RawMaterial::query()
            ->where('is_active', true)
            ->whereColumn('current_stock', '<=', 'min_stock')
            ->count();
    }

    public function activeReservationsCount(): int
    {
        if (! $this->tableExists('reservations')) {
            return 0;
        }

        return DB::table('reservations')
            ->where('tenant_id', tenant('id'))
            ->whereIn('status', ['pending', 'confirmed', 'arrived'])
            ->whereDate('reservation_date', today())
            ->count();
    }

    public function activeDeliveriesCount(): int
    {
        if (! $this->tableExists('delivery_orders')) {
            return 0;
        }

        return DB::table('delivery_orders')
            ->where('tenant_id', tenant('id'))
            ->whereIn('status', ['waiting', 'processing', 'cooking', 'ready', 'delivering'])
            ->count();
    }

    public function openTicketsCount(): int
    {
        if (! $this->tableExists('support_tickets')) {
            return 0;
        }

        return DB::table('support_tickets')
            ->where('tenant_id', tenant('id'))
            ->whereIn('status', ['open', 'assigned', 'pending'])
            ->count();
    }

    public function salesChartData(?int $outletId, Carbon $from, Carbon $to, string $period = 'daily'): Collection
    {
        $dateFormat = match ($period) {
            'monthly' => '%Y-%m',
            'weekly' => '%x-W%v',
            default => '%Y-%m-%d',
        };

        return SaleTransaction::query()
            ->completed()
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw("DATE_FORMAT(created_at, '{$dateFormat}') as label")
            ->selectRaw('SUM(grand_total) as revenue')
            ->selectRaw('COUNT(*) as transactions')
            ->groupBy('label')
            ->orderBy('label')
            ->get();
    }

    public function topProducts(?int $outletId, Carbon $from, Carbon $to, int $limit = 10): Collection
    {
        return SaleTransactionItem::query()
            ->join('sale_transactions', 'sale_transactions.id', '=', 'sale_transaction_items.transaction_id')
            ->where('sale_transactions.status', 'completed')
            ->where('sale_transactions.tenant_id', tenant('id'))
            ->when($outletId, fn ($q) => $q->where('sale_transactions.outlet_id', $outletId))
            ->whereBetween('sale_transactions.created_at', [$from, $to])
            ->selectRaw('sale_transaction_items.product_id')
            ->selectRaw('sale_transaction_items.product_name')
            ->selectRaw('SUM(sale_transaction_items.quantity) as total_qty')
            ->selectRaw('SUM(sale_transaction_items.subtotal) as total_revenue')
            ->groupBy('sale_transaction_items.product_id', 'sale_transaction_items.product_name')
            ->orderByDesc('total_revenue')
            ->limit($limit)
            ->get();
    }

    public function outletPerformance(Carbon $from, Carbon $to): Collection
    {
        return Outlet::query()
            ->leftJoin('sale_transactions', function ($join) use ($from, $to) {
                $join->on('sale_transactions.outlet_id', '=', 'outlets.id')
                    ->where('sale_transactions.status', 'completed')
                    ->whereBetween('sale_transactions.created_at', [$from, $to]);
            })
            ->where('outlets.tenant_id', tenant('id'))
            ->where('outlets.is_active', true)
            ->selectRaw('outlets.id')
            ->selectRaw('outlets.name')
            ->selectRaw('outlets.code')
            ->selectRaw('COALESCE(SUM(sale_transactions.grand_total), 0) as revenue')
            ->selectRaw('COUNT(sale_transactions.id) as transactions')
            ->groupBy('outlets.id', 'outlets.name', 'outlets.code')
            ->orderByDesc('revenue')
            ->get();
    }

    public function recentTransactions(?int $outletId, int $limit = 10): Collection
    {
        return SaleTransaction::query()
            ->with(['outlet:id,name,code', 'cashier:id,name'])
            ->completed()
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->latest()
            ->limit($limit)
            ->get();
    }

    public function memberGrowthChart(Carbon $from, Carbon $to): Collection
    {
        return Member::query()
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw("DATE_FORMAT(created_at, '%Y-%m-%d') as label")
            ->selectRaw('COUNT(*) as count')
            ->groupBy('label')
            ->orderBy('label')
            ->get();
    }

    protected function tableExists(string $table): bool
    {
        return DB::getSchemaBuilder()->hasTable($table);
    }
}