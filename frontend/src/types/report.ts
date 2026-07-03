export interface ReportFilters {
  date_from?: string;
  date_to?: string;
  outlet_id?: number;
  type?: "daily" | "weekly" | "monthly";
  format?: "json";
}

export interface ReportSummary {
  total_revenue: number;
  total_transactions: number;
  average_transaction: number;
  total_items_sold?: number;
  total_members?: number;
  new_members?: number;
  stock_movements?: number;
  low_stock_count?: number;
}

export interface SalesReportPoint {
  label: string;
  revenue: number;
  transactions: number;
  items_sold?: number;
}

export interface SalesReport {
  summary: ReportSummary;
  chart: SalesReportPoint[];
}

export interface ProductReportItem {
  product_id: number;
  product_name: string;
  sku?: string;
  category_name?: string;
  total_qty: number;
  total_revenue: number;
  profit?: number;
}

export interface ProductReport {
  summary: ReportSummary;
  items: ProductReportItem[];
}

export interface InventoryReportItem {
  product_id: number;
  product_name: string;
  sku?: string;
  opening_stock: number;
  stock_in: number;
  stock_out: number;
  closing_stock: number;
  movement_count: number;
}

export interface InventoryReport {
  summary: ReportSummary;
  items: InventoryReportItem[];
}

export interface MemberReportPoint {
  label: string;
  new_members: number;
  active_members: number;
  total_points_earned?: number;
}

export interface MemberReport {
  summary: ReportSummary;
  chart: MemberReportPoint[];
}

export interface ExportReportPayload {
  report_type: "sales" | "products" | "inventory" | "members";
  format: "csv" | "xlsx" | "pdf";
  date_from?: string;
  date_to?: string;
  outlet_id?: number;
  type?: "daily" | "weekly" | "monthly";
}

export interface ReportExportStatus {
  uuid: string;
  report_type: string;
  format: string;
  status: "pending" | "processing" | "completed" | "failed";
  storage_path?: string | null;
  error_message?: string | null;
  download_url?: string | null;
  generated_at?: string | null;
  created_at?: string;
}

export type ExportReportResult = ReportExportStatus;