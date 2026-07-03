"use client";

import { useMemo, useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  AlertTriangle,
  CalendarCheck,
  DollarSign,
  Package,
  ShoppingCart,
  Truck,
  Users,
} from "lucide-react";
import { QuickActions } from "@/components/dashboard/quick-actions";
import { SetupChecklistCard } from "@/components/dashboard/setup-checklist-card";
import { CustomerChart } from "@/components/dashboard/customer-chart";
import { KpiCard } from "@/components/dashboard/kpi-card";
import { LiveFeed } from "@/components/dashboard/live-feed";
import { OutletChart } from "@/components/dashboard/outlet-chart";
import { OutletSelector } from "@/components/dashboard/outlet-selector";
import { ProductChart } from "@/components/dashboard/product-chart";
import { SalesChart } from "@/components/dashboard/sales-chart";
import { getMe } from "@/lib/api/auth";
import {
  getCustomerGrowth,
  getDashboardKpi,
  getLiveFeed,
  getOutletPerformance,
  getOutlets,
  getProductPerformance,
  getSalesChart,
} from "@/lib/api/dashboard";
import { QueryErrorState } from "@/components/ui/query-error-state";
import { getErrorMessage } from "@/lib/api/client";
import { formatCurrency } from "@/lib/utils/format";
import { useAuthStore } from "@/stores/auth-store";
import type { DashboardFilters } from "@/types/dashboard";

export default function DashboardPage() {
  const { user, tenant } = useAuthStore();
  const [outletId, setOutletId] = useState<number | undefined>();

  const filters: DashboardFilters = useMemo(
    () => (outletId ? { outlet_id: outletId } : {}),
    [outletId]
  );

  const filterKey = outletId ?? "all";

  useQuery({
    queryKey: ["auth", "me"],
    queryFn: getMe,
    staleTime: 5 * 60 * 1000,
  });

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const {
    data: kpi,
    isLoading: kpiLoading,
    isError: kpiError,
    error: kpiQueryError,
    refetch: refetchKpi,
  } = useQuery({
    queryKey: ["dashboard", "kpi", filterKey],
    queryFn: () => getDashboardKpi(filters),
    staleTime: 60 * 1000,
  });

  const { data: salesData = [], isLoading: salesLoading } = useQuery({
    queryKey: ["dashboard", "sales", filterKey],
    queryFn: () => getSalesChart(filters),
    staleTime: 60 * 1000,
  });

  const { data: productData = [], isLoading: productLoading } = useQuery({
    queryKey: ["dashboard", "products", filterKey],
    queryFn: () => getProductPerformance(filters),
    staleTime: 60 * 1000,
  });

  const { data: customerData = [], isLoading: customerLoading } = useQuery({
    queryKey: ["dashboard", "customers", filterKey],
    queryFn: () => getCustomerGrowth(filters),
    staleTime: 60 * 1000,
  });

  const showOutletChart = !outletId;

  const { data: outletData = [], isLoading: outletLoading } = useQuery({
    queryKey: ["dashboard", "outlets-performance", filterKey],
    queryFn: () => getOutletPerformance(filters),
    enabled: showOutletChart,
    staleTime: 60 * 1000,
  });

  const { data: liveFeed = [], isLoading: feedLoading } = useQuery({
    queryKey: ["dashboard", "live-feed", filterKey],
    queryFn: () => getLiveFeed(filters),
    refetchInterval: 30 * 1000,
    staleTime: 15 * 1000,
  });

  const isNewBusiness =
    !kpiLoading &&
    (kpi?.revenue_today ?? 0) === 0 &&
    (kpi?.transactions_today ?? 0) === 0;

  return (
    <div className="space-y-8">
      <SetupChecklistCard />

      <div>
        <h2 className="mb-3 text-sm font-semibold text-muted-foreground">
          Aksi Cepat
        </h2>
        <QuickActions />
      </div>

      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">
            Selamat datang, {user?.name ?? "Pengguna"}!
          </h1>
          <p className="mt-1 text-muted-foreground">
            {tenant
              ? `Dashboard ${tenant.name} — CreativePOS by Creative Network`
              : "Dashboard CreativePOS by Creative Network"}
          </p>
        </div>
        <OutletSelector
          outlets={outlets}
          value={outletId}
          onChange={setOutletId}
        />
      </div>

      {kpiError && (
        <QueryErrorState
          message={getErrorMessage(kpiQueryError)}
          onRetry={() => void refetchKpi()}
        />
      )}

      {isNewBusiness && !kpiError && (
        <div className="rounded-xl border border-dashed border-primary/30 bg-primary/5 px-6 py-5 text-center sm:text-left">
          <p className="text-sm font-medium text-primary">
            Bisnis Anda siap beroperasi!
          </p>
          <p className="mt-1 text-sm text-muted-foreground">
            Mulai dari POS untuk transaksi pertama, atau lengkapi produk di
            inventori.
          </p>
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          title="Pendapatan Hari Ini"
          value={formatCurrency(kpi?.revenue_today ?? 0)}
          description={`Minggu ini: ${formatCurrency(kpi?.revenue_week ?? 0)}`}
          icon={DollarSign}
          colorClass="text-emerald-600 bg-emerald-50"
          isLoading={kpiLoading}
        />
        <KpiCard
          title="Transaksi Hari Ini"
          value={String(kpi?.transactions_today ?? 0)}
          description={`Bulan ini: ${kpi?.transactions_month ?? 0} transaksi`}
          icon={ShoppingCart}
          colorClass="text-blue-600 bg-blue-50"
          isLoading={kpiLoading}
        />
        <KpiCard
          title="Member Baru"
          value={String(kpi?.new_members_today ?? 0)}
          description={`Bulan ini: ${kpi?.new_members_month ?? 0} member`}
          icon={Users}
          colorClass="text-violet-600 bg-violet-50"
          isLoading={kpiLoading}
        />
        <KpiCard
          title="Stok Menipis"
          value={String(kpi?.stock_alerts ?? 0)}
          description={`Bahan baku: ${kpi?.raw_material_alerts ?? 0} alert`}
          icon={Package}
          colorClass="text-amber-600 bg-amber-50"
          isLoading={kpiLoading}
        />
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          title="Pendapatan Bulan Ini"
          value={formatCurrency(kpi?.revenue_month ?? 0)}
          description={`Tahun ini: ${formatCurrency(kpi?.revenue_year ?? 0)}`}
          icon={DollarSign}
          colorClass="text-emerald-600 bg-emerald-50"
          isLoading={kpiLoading}
        />
        <KpiCard
          title="Reservasi Aktif"
          value={String(kpi?.active_reservations ?? 0)}
          description="Menunggu konfirmasi"
          icon={CalendarCheck}
          colorClass="text-sky-600 bg-sky-50"
          isLoading={kpiLoading}
        />
        <KpiCard
          title="Pengiriman Aktif"
          value={String(kpi?.active_deliveries ?? 0)}
          description="Sedang diproses"
          icon={Truck}
          colorClass="text-orange-600 bg-orange-50"
          isLoading={kpiLoading}
        />
        <KpiCard
          title="Tiket Terbuka"
          value={String(kpi?.open_tickets ?? 0)}
          description="Perlu ditindaklanjuti"
          icon={AlertTriangle}
          colorClass="text-rose-600 bg-rose-50"
          isLoading={kpiLoading}
        />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <SalesChart data={salesData} isLoading={salesLoading} />
        <ProductChart data={productData} isLoading={productLoading} />
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <CustomerChart data={customerData} isLoading={customerLoading} />
        {showOutletChart ? (
          <OutletChart data={outletData} isLoading={outletLoading} />
        ) : (
          <LiveFeed data={liveFeed} isLoading={feedLoading} />
        )}
      </div>

      {showOutletChart && (
        <LiveFeed data={liveFeed} isLoading={feedLoading} />
      )}
    </div>
  );
}