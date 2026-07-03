import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { PaginatedMeta } from "@/types/loyalty";
import { getToken } from "@/lib/utils/token";
import type {
  ExportReportPayload,
  InventoryReport,
  MemberReport,
  ProductReport,
  ReportExportStatus,
  ReportFilters,
  ReportSummary,
  SalesReport,
  SalesReportPoint,
} from "@/types/report";

function buildParams(
  filters?: ReportFilters
): Record<string, string | number> {
  const params: Record<string, string | number> = { format: "json" };
  if (filters?.date_from) params.date_from = filters.date_from;
  if (filters?.date_to) params.date_to = filters.date_to;
  if (filters?.outlet_id) params.outlet_id = filters.outlet_id;
  if (filters?.type) params.type = filters.type;
  return params;
}

type RawSalesRow = {
  period: string;
  revenue: number;
  transactions: number;
};

type RawProductRow = {
  product_id: number;
  product_name: string;
  sku?: string;
  total_qty: number;
  total_revenue: number;
};

type RawInventoryRow = {
  type: string;
  movement_count: number;
  total_quantity: number;
};

type RawMemberRow = {
  period: string;
  new_members: number;
  active_members: number;
};

function buildSalesSummary(chart: SalesReportPoint[]): ReportSummary {
  const totalRevenue = chart.reduce((sum, row) => sum + row.revenue, 0);
  const totalTransactions = chart.reduce((sum, row) => sum + row.transactions, 0);

  return {
    total_revenue: totalRevenue,
    total_transactions: totalTransactions,
    average_transaction:
      totalTransactions > 0 ? totalRevenue / totalTransactions : 0,
  };
}

function normalizeSalesReport(raw: RawSalesRow[]): SalesReport {
  const chart = raw.map((row) => ({
    label: row.period,
    revenue: row.revenue,
    transactions: row.transactions,
  }));

  return {
    summary: buildSalesSummary(chart),
    chart,
  };
}

function normalizeProductsReport(raw: RawProductRow[]): ProductReport {
  const totalRevenue = raw.reduce((sum, row) => sum + row.total_revenue, 0);
  const totalQty = raw.reduce((sum, row) => sum + row.total_qty, 0);

  return {
    summary: {
      total_revenue: totalRevenue,
      total_transactions: raw.length,
      average_transaction: raw.length > 0 ? totalRevenue / raw.length : 0,
      total_items_sold: totalQty,
    },
    items: raw.map((row) => ({
      product_id: row.product_id,
      product_name: row.product_name,
      sku: row.sku,
      total_qty: row.total_qty,
      total_revenue: row.total_revenue,
    })),
  };
}

function normalizeInventoryReport(raw: RawInventoryRow[]): InventoryReport {
  const stockIn = raw
    .filter((row) => row.type === "in")
    .reduce((sum, row) => sum + row.total_quantity, 0);
  const stockOut = raw
    .filter((row) => row.type === "out")
    .reduce((sum, row) => sum + row.total_quantity, 0);

  return {
    summary: {
      total_revenue: 0,
      total_transactions: raw.reduce((sum, row) => sum + row.movement_count, 0),
      average_transaction: 0,
      stock_movements: raw.reduce((sum, row) => sum + row.movement_count, 0),
      low_stock_count: 0,
    },
    items: raw.map((row, index) => ({
      product_id: index + 1,
      product_name: `Pergerakan ${row.type}`,
      sku: row.type,
      opening_stock: 0,
      stock_in: row.type === "in" ? row.total_quantity : 0,
      stock_out: row.type === "out" ? row.total_quantity : 0,
      closing_stock: row.type === "in" ? stockIn - stockOut : 0,
      movement_count: row.movement_count,
    })),
  };
}

function normalizeMembersReport(raw: RawMemberRow[]): MemberReport {
  const chart = raw.map((row) => ({
    label: row.period,
    new_members: row.new_members,
    active_members: row.active_members,
  }));

  const newMembers = chart.reduce((sum, row) => sum + row.new_members, 0);

  return {
    summary: {
      total_revenue: 0,
      total_transactions: 0,
      average_transaction: 0,
      new_members: newMembers,
      total_members: chart.at(-1)?.active_members ?? 0,
    },
    chart,
  };
}

export async function getSalesReport(
  filters?: ReportFilters
): Promise<SalesReport> {
  const { data } = await apiClient.get<ApiResponse<RawSalesRow[]>>(
    "/reports/sales",
    { params: buildParams(filters) }
  );
  return normalizeSalesReport(data.data ?? []);
}

export async function getProductsReport(
  filters?: ReportFilters
): Promise<ProductReport> {
  const { data } = await apiClient.get<ApiResponse<RawProductRow[]>>(
    "/reports/products",
    { params: buildParams(filters) }
  );
  return normalizeProductsReport(data.data ?? []);
}

export async function getInventoryReport(
  filters?: ReportFilters
): Promise<InventoryReport> {
  const { data } = await apiClient.get<ApiResponse<RawInventoryRow[]>>(
    "/reports/inventory",
    { params: buildParams(filters) }
  );
  return normalizeInventoryReport(data.data ?? []);
}

export interface ProfitLossReport {
  revenue: number;
  cost: number;
  gross_profit: number;
  margin_percent: number;
}

export interface CashFlowRow {
  payment_method: string;
  payment_method_name: string;
  payment_type: string;
  total_amount: number;
  payment_count: number;
}

export async function getProfitLossReport(
  filters?: ReportFilters
): Promise<ProfitLossReport> {
  const { data } = await apiClient.get<ApiResponse<ProfitLossReport>>(
    "/reports/profit-loss",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getCashFlowReport(
  filters?: ReportFilters
): Promise<CashFlowRow[]> {
  const { data } = await apiClient.get<ApiResponse<CashFlowRow[]>>(
    "/reports/cash-flow",
    { params: buildParams(filters) }
  );
  return data.data;
}

export async function getMembersReport(
  filters?: ReportFilters
): Promise<MemberReport> {
  const { data } = await apiClient.get<ApiResponse<RawMemberRow[]>>(
    "/reports/members",
    { params: buildParams(filters) }
  );
  return normalizeMembersReport(data.data ?? []);
}

export async function requestReportExport(
  payload: ExportReportPayload
): Promise<ReportExportStatus> {
  const { data } = await apiClient.post<ApiResponse<ReportExportStatus>>(
    "/reports/export",
    {
      report_type: payload.report_type,
      format: payload.format,
      date_from: payload.date_from,
      date_to: payload.date_to,
      outlet_id: payload.outlet_id,
      type: payload.type ?? "daily",
    }
  );
  return data.data;
}

export async function getExportStatus(uuid: string): Promise<ReportExportStatus> {
  const { data } = await apiClient.get<ApiResponse<ReportExportStatus>>(
    `/reports/export/${uuid}`
  );
  return data.data;
}

export async function downloadReportExport(
  uuid: string,
  meta?: Pick<ReportExportStatus, "report_type" | "format">
): Promise<void> {
  const baseUrl =
    process.env.NEXT_PUBLIC_API_URL ?? "http://10.110.1.15:8000/api/v1";
  const token = getToken();

  const response = await fetch(`${baseUrl}/reports/export/${uuid}/download`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });

  if (!response.ok) {
    throw new Error("Gagal mengunduh file export");
  }

  const blob = await response.blob();
  const extension = meta?.format ?? "xlsx";
  const reportType = meta?.report_type ?? "report";
  const filename = `laporan-${reportType}-${uuid.slice(0, 8)}.${extension}`;

  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

export async function getReportExports(params?: {
  page?: number;
  per_page?: number;
}): Promise<{ data: ReportExportStatus[]; meta: PaginatedMeta }> {
  const { data } = await apiClient.get<
    ApiResponse<ReportExportStatus[]> & { meta?: PaginatedMeta }
  >("/reports/exports", { params });

  return {
    data: data.data,
    meta: data.meta ?? {
      current_page: 1,
      per_page: data.data.length,
      total: data.data.length,
      last_page: 1,
    },
  };
}

/** @deprecated Use requestReportExport */
export async function exportReport(payload: ExportReportPayload) {
  return requestReportExport(payload);
}