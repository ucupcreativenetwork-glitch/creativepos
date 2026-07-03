<?php

namespace App\Modules\Report\Repositories;

use App\Modules\Inventory\Models\StockMovement;
use App\Modules\Loyalty\Models\Member;
use App\Modules\POS\Models\SalePayment;
use App\Modules\POS\Models\SaleTransaction;
use App\Modules\POS\Models\SaleTransactionItem;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class ReportRepository
{
    public function salesReport(?int $outletId, Carbon $from, Carbon $to, string $type = 'daily'): Collection
    {
        $dateFormat = match ($type) {
            'monthly' => '%Y-%m',
            'weekly' => '%x-W%v',
            default => '%Y-%m-%d',
        };

        return SaleTransaction::query()
            ->completed()
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw("DATE_FORMAT(created_at, '{$dateFormat}') as period")
            ->selectRaw('SUM(grand_total) as revenue')
            ->selectRaw('SUM(subtotal) as subtotal')
            ->selectRaw('SUM(discount_total) as discount_total')
            ->selectRaw('SUM(tax_total) as tax_total')
            ->selectRaw('COUNT(*) as transactions')
            ->groupBy('period')
            ->orderBy('period')
            ->get();
    }

    public function topProducts(?int $outletId, Carbon $from, Carbon $to, int $limit = 20): Collection
    {
        return SaleTransactionItem::query()
            ->join('sale_transactions', 'sale_transactions.id', '=', 'sale_transaction_items.transaction_id')
            ->where('sale_transactions.status', 'completed')
            ->where('sale_transactions.tenant_id', tenant('id'))
            ->when($outletId, fn ($q) => $q->where('sale_transactions.outlet_id', $outletId))
            ->whereBetween('sale_transactions.created_at', [$from, $to])
            ->selectRaw('sale_transaction_items.product_id')
            ->selectRaw('sale_transaction_items.product_name')
            ->selectRaw('sale_transaction_items.sku')
            ->selectRaw('SUM(sale_transaction_items.quantity) as total_qty')
            ->selectRaw('SUM(sale_transaction_items.subtotal) as total_revenue')
            ->groupBy(
                'sale_transaction_items.product_id',
                'sale_transaction_items.product_name',
                'sale_transaction_items.sku',
            )
            ->orderByDesc('total_revenue')
            ->limit($limit)
            ->get();
    }

    public function inventoryMovements(?int $outletId, Carbon $from, Carbon $to): Collection
    {
        return StockMovement::query()
            ->when($outletId, function ($q) use ($outletId): void {
                $q->whereHas('warehouse', fn ($w) => $w->where('outlet_id', $outletId));
            })
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw('type')
            ->selectRaw('COUNT(*) as movement_count')
            ->selectRaw('SUM(quantity) as total_quantity')
            ->groupBy('type')
            ->orderBy('type')
            ->get();
    }

    public function inventoryMovementDetails(?int $outletId, Carbon $from, Carbon $to, int $limit = 5000): Collection
    {
        return StockMovement::query()
            ->with([
                'product:id,name,sku',
                'warehouse:id,name,code,outlet_id',
            ])
            ->when($outletId, function ($q) use ($outletId): void {
                $q->whereHas('warehouse', fn ($w) => $w->where('outlet_id', $outletId));
            })
            ->whereBetween('created_at', [$from, $to])
            ->orderByDesc('created_at')
            ->limit($limit)
            ->get();
    }

    public function memberGrowth(Carbon $from, Carbon $to, string $type = 'daily'): Collection
    {
        $dateFormat = match ($type) {
            'monthly' => '%Y-%m',
            'weekly' => '%x-W%v',
            default => '%Y-%m-%d',
        };

        return Member::query()
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw("DATE_FORMAT(created_at, '{$dateFormat}') as period")
            ->selectRaw('COUNT(*) as new_members')
            ->selectRaw('SUM(CASE WHEN status = \'active\' THEN 1 ELSE 0 END) as active_members')
            ->groupBy('period')
            ->orderBy('period')
            ->get();
    }

    public function profitLoss(?int $outletId, Carbon $from, Carbon $to): array
    {
        $revenue = (float) SaleTransaction::query()
            ->completed()
            ->when($outletId, fn ($q) => $q->where('outlet_id', $outletId))
            ->whereBetween('created_at', [$from, $to])
            ->sum('grand_total');

        $cost = (float) SaleTransactionItem::query()
            ->join('sale_transactions', 'sale_transactions.id', '=', 'sale_transaction_items.transaction_id')
            ->leftJoin('products', 'products.id', '=', 'sale_transaction_items.product_id')
            ->where('sale_transactions.status', 'completed')
            ->where('sale_transactions.tenant_id', tenant('id'))
            ->when($outletId, fn ($q) => $q->where('sale_transactions.outlet_id', $outletId))
            ->whereBetween('sale_transactions.created_at', [$from, $to])
            ->selectRaw('SUM(sale_transaction_items.quantity * COALESCE(products.cost_price, 0)) as total_cost')
            ->value('total_cost');

        $grossProfit = $revenue - $cost;

        return [
            'revenue' => $revenue,
            'cost' => $cost,
            'gross_profit' => $grossProfit,
            'margin_percent' => $revenue > 0 ? round(($grossProfit / $revenue) * 100, 2) : 0,
        ];
    }

    public function cashFlow(?int $outletId, Carbon $from, Carbon $to): Collection
    {
        return SalePayment::query()
            ->join('sale_transactions', 'sale_transactions.id', '=', 'sale_payments.transaction_id')
            ->join('payment_methods', 'payment_methods.id', '=', 'sale_payments.payment_method_id')
            ->where('sale_transactions.status', 'completed')
            ->where('sale_payments.status', 'completed')
            ->when($outletId, fn ($q) => $q->where('sale_transactions.outlet_id', $outletId))
            ->whereBetween('sale_payments.paid_at', [$from, $to])
            ->selectRaw('payment_methods.code as payment_method')
            ->selectRaw('payment_methods.name as payment_method_name')
            ->selectRaw('payment_methods.type as payment_type')
            ->selectRaw('SUM(sale_payments.amount) as total_amount')
            ->selectRaw('COUNT(*) as payment_count')
            ->groupBy('payment_methods.code', 'payment_methods.name', 'payment_methods.type')
            ->orderByDesc('total_amount')
            ->get();
    }

}