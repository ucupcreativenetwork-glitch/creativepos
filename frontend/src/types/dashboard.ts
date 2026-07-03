export interface DashboardKpi {
  revenue_today: number;
  revenue_week: number;
  revenue_month: number;
  revenue_year: number;
  transactions_today: number;
  transactions_week: number;
  transactions_month: number;
  new_members_today: number;
  new_members_month: number;
  active_reservations: number;
  active_deliveries: number;
  open_tickets: number;
  stock_alerts: number;
  raw_material_alerts?: number;
}

export interface SalesChartPoint {
  label: string;
  revenue: number;
  transactions: number;
}

export interface ProductPerformance {
  product_id: number;
  product_name: string;
  total_qty: number;
  total_revenue: number;
}

export interface CustomerGrowthPoint {
  label: string;
  count: number;
}

export interface OutletPerformance {
  outlet_id: number;
  name: string;
  code: string;
  revenue: number;
  transactions: number;
}

export interface LiveTransaction {
  id: number;
  uuid: string;
  transaction_number: string;
  outlet: string | null;
  cashier: string | null;
  grand_total: number;
  order_type: string;
  completed_at: string | null;
  created_at: string | null;
}

export interface Outlet {
  id: number;
  uuid: string;
  name: string;
  code: string;
  is_default: boolean;
}

export interface DashboardFilters {
  outlet_id?: number;
  date_from?: string;
  date_to?: string;
  period?: "daily" | "weekly" | "monthly";
}