"use client";

import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import {
  Package,
  ShoppingCart,
  TrendingUp,
  Users,
} from "lucide-react";
import { KpiCard } from "@/components/dashboard/kpi-card";
import { ReportExportButton } from "@/components/reports/report-export-button";
import { ReportExportHistory } from "@/components/reports/report-export-history";
import { OutletSelector } from "@/components/dashboard/outlet-selector";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { usePackageFeatures } from "@/hooks/usePackageFeatures";
import { getOutlets } from "@/lib/api/dashboard";
import {
  getCashFlowReport,
  getInventoryReport,
  getMembersReport,
  getProductsReport,
  getProfitLossReport,
  getSalesReport,
} from "@/lib/api/reports";
import { formatCurrency } from "@/lib/utils/format";
import type { ReportFilters } from "@/types/report";

type ReportTab =
  | "sales"
  | "products"
  | "inventory"
  | "members"
  | "profit_loss"
  | "cash_flow";

const tabs: { key: ReportTab; label: string }[] = [
  { key: "sales", label: "Penjualan" },
  { key: "products", label: "Produk" },
  { key: "inventory", label: "Inventori" },
  { key: "members", label: "Member" },
  { key: "profit_loss", label: "Laba Rugi" },
  { key: "cash_flow", label: "Arus Kas" },
];

function getDefaultDateRange() {
  const to = new Date();
  const from = new Date();
  from.setDate(from.getDate() - 30);
  return {
    date_from: from.toISOString().split("T")[0],
    date_to: to.toISOString().split("T")[0],
  };
}

export default function ReportsPage() {
  const { hasFullReport } = usePackageFeatures();
  const defaults = getDefaultDateRange();
  const visibleTabs = tabs.filter(
    (t) =>
      t.key !== "profit_loss" && t.key !== "cash_flow" ? true : hasFullReport
  );
  const [activeTab, setActiveTab] = useState<ReportTab>("sales");
  const [dateFrom, setDateFrom] = useState(defaults.date_from);
  const [dateTo, setDateTo] = useState(defaults.date_to);
  const [outletId, setOutletId] = useState<number | undefined>();
  const filters: ReportFilters = useMemo(
    () => ({
      date_from: dateFrom,
      date_to: dateTo,
      outlet_id: outletId,
      type: "daily",
    }),
    [dateFrom, dateTo, outletId]
  );

  const filterKey = `${activeTab}-${dateFrom}-${dateTo}-${outletId ?? "all"}`;

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const { data: salesReport, isLoading: salesLoading } = useQuery({
    queryKey: ["reports", "sales", filterKey],
    queryFn: () => getSalesReport(filters),
    enabled: activeTab === "sales",
    staleTime: 60 * 1000,
  });

  const { data: productsReport, isLoading: productsLoading } = useQuery({
    queryKey: ["reports", "products", filterKey],
    queryFn: () => getProductsReport(filters),
    enabled: activeTab === "products",
    staleTime: 60 * 1000,
  });

  const { data: inventoryReport, isLoading: inventoryLoading } = useQuery({
    queryKey: ["reports", "inventory", filterKey],
    queryFn: () => getInventoryReport(filters),
    enabled: activeTab === "inventory",
    staleTime: 60 * 1000,
  });

  const { data: membersReport, isLoading: membersLoading } = useQuery({
    queryKey: ["reports", "members", filterKey],
    queryFn: () => getMembersReport(filters),
    enabled: activeTab === "members",
    staleTime: 60 * 1000,
  });

  const { data: profitLoss, isLoading: profitLossLoading } = useQuery({
    queryKey: ["reports", "profit-loss", filterKey],
    queryFn: () => getProfitLossReport(filters),
    enabled: activeTab === "profit_loss",
    staleTime: 60 * 1000,
  });

  const { data: cashFlow = [], isLoading: cashFlowLoading } = useQuery({
    queryKey: ["reports", "cash-flow", filterKey],
    queryFn: () => getCashFlowReport(filters),
    enabled: activeTab === "cash_flow",
    staleTime: 60 * 1000,
  });

  const isLoading =
    (activeTab === "sales" && salesLoading) ||
    (activeTab === "products" && productsLoading) ||
    (activeTab === "inventory" && inventoryLoading) ||
    (activeTab === "members" && membersLoading) ||
    (activeTab === "profit_loss" && profitLossLoading) ||
    (activeTab === "cash_flow" && cashFlowLoading);

  const summary =
    activeTab === "sales"
      ? salesReport?.summary
      : activeTab === "products"
        ? productsReport?.summary
        : activeTab === "inventory"
          ? inventoryReport?.summary
          : membersReport?.summary;

  const exportableTab =
    activeTab === "sales" ||
    activeTab === "products" ||
    activeTab === "inventory";

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Laporan</h1>
          <p className="mt-1 text-muted-foreground">
            Analisis penjualan, produk, inventori, dan member
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-3">
          <OutletSelector
            outlets={outlets}
            value={outletId}
            onChange={setOutletId}
          />
          {exportableTab ? (
            <ReportExportButton
              reportType={activeTab}
              dateFrom={dateFrom}
              dateTo={dateTo}
              outletId={outletId}
            />
          ) : (
            <p className="text-sm text-muted-foreground">
              Export file tersedia untuk tab Penjualan, Produk, dan Inventori
            </p>
          )}
        </div>
      </div>

      <Card>
        <CardContent className="flex flex-wrap items-end gap-4 pt-6">
          <div>
            <label className="mb-1.5 block text-xs font-medium text-muted-foreground">
              Dari Tanggal
            </label>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="h-9 rounded-lg border border-border bg-white px-3 text-sm"
            />
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-medium text-muted-foreground">
              Sampai Tanggal
            </label>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="h-9 rounded-lg border border-border bg-white px-3 text-sm"
            />
          </div>
        </CardContent>
      </Card>

      <div className="flex gap-2 overflow-x-auto border-b border-border">
        {visibleTabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            onClick={() => setActiveTab(tab.key)}
            className={`shrink-0 border-b-2 px-4 py-2.5 text-sm font-medium transition-colors ${
              activeTab === tab.key
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          title="Total Pendapatan"
          value={formatCurrency(summary?.total_revenue ?? 0)}
          icon={TrendingUp}
          colorClass="text-emerald-600 bg-emerald-50"
          isLoading={isLoading}
        />
        <KpiCard
          title="Total Transaksi"
          value={String(summary?.total_transactions ?? 0)}
          icon={ShoppingCart}
          colorClass="text-blue-600 bg-blue-50"
          isLoading={isLoading}
        />
        <KpiCard
          title="Rata-rata Transaksi"
          value={formatCurrency(summary?.average_transaction ?? 0)}
          icon={TrendingUp}
          colorClass="text-violet-600 bg-violet-50"
          isLoading={isLoading}
        />
        <KpiCard
          title={
            activeTab === "members"
              ? "Member Baru"
              : activeTab === "inventory"
                ? "Stok Menipis"
                : "Item Terjual"
          }
          value={String(
            activeTab === "members"
              ? (summary?.new_members ?? 0)
              : activeTab === "inventory"
                ? (summary?.low_stock_count ?? 0)
                : (summary?.total_items_sold ?? 0)
          )}
          icon={activeTab === "members" ? Users : Package}
          colorClass="text-amber-600 bg-amber-50"
          isLoading={isLoading}
        />
      </div>

      {activeTab === "sales" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Grafik Penjualan</CardTitle>
            <CardDescription>
              Pendapatan harian dalam periode terpilih
            </CardDescription>
          </CardHeader>
          <CardContent>
            {salesLoading ? (
              <div className="flex h-64 items-center justify-center">
                <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
              </div>
            ) : !(salesReport?.chart?.length ?? 0) ? (
              <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
                Belum ada data penjualan
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <LineChart data={salesReport?.chart ?? []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                  <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                  <YAxis
                    tick={{ fontSize: 12 }}
                    tickFormatter={(v) =>
                      new Intl.NumberFormat("id-ID", {
                        notation: "compact",
                      }).format(v)
                    }
                  />
                  <Tooltip
                    formatter={(value) => [
                      formatCurrency(Number(value ?? 0)),
                      "Pendapatan",
                    ]}
                  />
                  <Line
                    type="monotone"
                    dataKey="revenue"
                    stroke="#2563EB"
                    strokeWidth={2}
                    dot={{ r: 3 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      )}

      {activeTab === "products" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Produk Terlaris</CardTitle>
          </CardHeader>
          <CardContent>
            {productsLoading ? (
              <div className="h-64 animate-pulse rounded-lg bg-slate-100" />
            ) : !(productsReport?.items?.length ?? 0) ? (
              <p className="py-12 text-center text-muted-foreground">
                Belum ada data produk
              </p>
            ) : (
              <>
                <ResponsiveContainer width="100%" height={280}>
                  <BarChart
                    data={(productsReport?.items ?? []).slice(0, 10)}
                    layout="vertical"
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                    <XAxis type="number" tick={{ fontSize: 12 }} />
                    <YAxis
                      type="category"
                      dataKey="product_name"
                      width={120}
                      tick={{ fontSize: 11 }}
                    />
                    <Tooltip
                      formatter={(value) => [
                        formatCurrency(Number(value ?? 0)),
                        "Pendapatan",
                      ]}
                    />
                    <Bar dataKey="total_revenue" fill="#2563EB" radius={4} />
                  </BarChart>
                </ResponsiveContainer>
                <div className="mt-4 overflow-x-auto rounded-lg border border-border">
                  <table className="w-full text-sm">
                    <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                      <tr>
                        <th className="px-4 py-3 font-medium">Produk</th>
                        <th className="px-4 py-3 font-medium text-right">Qty</th>
                        <th className="px-4 py-3 font-medium text-right">
                          Pendapatan
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {(productsReport?.items ?? []).map((item) => (
                        <tr key={item.product_id}>
                          <td className="px-4 py-3 font-medium">
                            {item.product_name}
                          </td>
                          <td className="px-4 py-3 text-right">
                            {item.total_qty}
                          </td>
                          <td className="px-4 py-3 text-right">
                            {formatCurrency(item.total_revenue)}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      )}

      {activeTab === "inventory" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Pergerakan Stok</CardTitle>
          </CardHeader>
          <CardContent>
            {inventoryLoading ? (
              <div className="h-64 animate-pulse rounded-lg bg-slate-100" />
            ) : !(inventoryReport?.items?.length ?? 0) ? (
              <p className="py-12 text-center text-muted-foreground">
                Belum ada data inventori
              </p>
            ) : (
              <div className="overflow-x-auto rounded-lg border border-border">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                    <tr>
                      <th className="px-4 py-3 font-medium">Produk</th>
                      <th className="px-4 py-3 font-medium text-right">Awal</th>
                      <th className="px-4 py-3 font-medium text-right">Masuk</th>
                      <th className="px-4 py-3 font-medium text-right">Keluar</th>
                      <th className="px-4 py-3 font-medium text-right">Akhir</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {(inventoryReport?.items ?? []).map((item) => (
                      <tr key={item.product_id}>
                        <td className="px-4 py-3 font-medium">
                          {item.product_name}
                        </td>
                        <td className="px-4 py-3 text-right">
                          {item.opening_stock}
                        </td>
                        <td className="px-4 py-3 text-right text-emerald-600">
                          +{item.stock_in}
                        </td>
                        <td className="px-4 py-3 text-right text-rose-600">
                          -{item.stock_out}
                        </td>
                        <td className="px-4 py-3 text-right font-medium">
                          {item.closing_stock}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {activeTab === "profit_loss" && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <KpiCard
            title="Pendapatan"
            value={formatCurrency(profitLoss?.revenue ?? 0)}
            icon={TrendingUp}
          />
          <KpiCard
            title="HPP / Biaya"
            value={formatCurrency(profitLoss?.cost ?? 0)}
            icon={Package}
          />
          <KpiCard
            title="Laba Kotor"
            value={formatCurrency(profitLoss?.gross_profit ?? 0)}
            icon={ShoppingCart}
          />
          <KpiCard
            title="Margin"
            value={`${profitLoss?.margin_percent ?? 0}%`}
            icon={TrendingUp}
          />
        </div>
      )}

      {activeTab === "cash_flow" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Arus Kas per Metode Bayar</CardTitle>
            <CardDescription>
              Total penerimaan pembayaran dalam periode terpilih
            </CardDescription>
          </CardHeader>
          <CardContent>
            {cashFlowLoading ? (
              <div className="h-32 animate-pulse rounded-lg bg-slate-100" />
            ) : cashFlow.length === 0 ? (
              <p className="py-8 text-center text-muted-foreground">
                Belum ada data arus kas
              </p>
            ) : (
              <div className="overflow-x-auto rounded-lg border border-border">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                    <tr>
                      <th className="px-4 py-3 font-medium">Metode</th>
                      <th className="px-4 py-3 font-medium">Tipe</th>
                      <th className="px-4 py-3 font-medium text-right">Transaksi</th>
                      <th className="px-4 py-3 font-medium text-right">Total</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {cashFlow.map((row) => (
                      <tr key={row.payment_method}>
                        <td className="px-4 py-3 font-medium">
                          {row.payment_method_name}
                        </td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {row.payment_type}
                        </td>
                        <td className="px-4 py-3 text-right">
                          {row.payment_count}
                        </td>
                        <td className="px-4 py-3 text-right font-medium">
                          {formatCurrency(row.total_amount)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {activeTab === "members" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Pertumbuhan Member</CardTitle>
          </CardHeader>
          <CardContent>
            {membersLoading ? (
              <div className="flex h-64 items-center justify-center">
                <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
              </div>
            ) : !(membersReport?.chart?.length ?? 0) ? (
              <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
                Belum ada data member
              </div>
            ) : (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={membersReport?.chart ?? []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                  <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                  <YAxis tick={{ fontSize: 12 }} />
                  <Tooltip />
                  <Bar
                    dataKey="new_members"
                    name="Member Baru"
                    fill="#2563EB"
                    radius={[4, 4, 0, 0]}
                  />
                  <Bar
                    dataKey="active_members"
                    name="Member Aktif"
                    fill="#10b981"
                    radius={[4, 4, 0, 0]}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>
      )}

      <ReportExportHistory />
    </div>
  );
}