import { apiClient } from "@/lib/api/client";
import type {
  CustomerGrowthPoint,
  DashboardFilters,
  DashboardKpi,
  LiveTransaction,
  Outlet,
  OutletPerformance,
  ProductPerformance,
  SalesChartPoint,
} from "@/types/dashboard";
import type { ApiResponse } from "@/types/auth";

function buildParams(filters?: DashboardFilters): Record<string, string | number> {
  const params: Record<string, string | number> = {};
  if (filters?.outlet_id) params.outlet_id = filters.outlet_id;
  if (filters?.date_from) params.date_from = filters.date_from;
  if (filters?.date_to) params.date_to = filters.date_to;
  if (filters?.period) params.period = filters.period;
  return params;
}

export async function getDashboardKpi(
  filters?: DashboardFilters
): Promise<DashboardKpi> {
  const { data } = await apiClient.get<ApiResponse<DashboardKpi>>(
    "/dashboard/kpi",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getSalesChart(
  filters?: DashboardFilters
): Promise<SalesChartPoint[]> {
  const { data } = await apiClient.get<ApiResponse<SalesChartPoint[]>>(
    "/dashboard/charts/sales",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getProductPerformance(
  filters?: DashboardFilters
): Promise<ProductPerformance[]> {
  const { data } = await apiClient.get<ApiResponse<ProductPerformance[]>>(
    "/dashboard/charts/products",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getCustomerGrowth(
  filters?: DashboardFilters
): Promise<CustomerGrowthPoint[]> {
  const { data } = await apiClient.get<ApiResponse<CustomerGrowthPoint[]>>(
    "/dashboard/charts/customers",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getOutletPerformance(
  filters?: DashboardFilters
): Promise<OutletPerformance[]> {
  const { data } = await apiClient.get<ApiResponse<OutletPerformance[]>>(
    "/dashboard/charts/outlets",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getLiveFeed(
  filters?: DashboardFilters
): Promise<LiveTransaction[]> {
  const { data } = await apiClient.get<ApiResponse<LiveTransaction[]>>(
    "/dashboard/live-feed",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getOutlets(): Promise<Outlet[]> {
  const { data } = await apiClient.get<ApiResponse<Outlet[]>>(
    "/dashboard/outlets"
  );
  return data.data;
}