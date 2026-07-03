import type { LucideIcon } from "lucide-react";
import {
  BarChart3,
  CalendarDays,
  ChefHat,
  Headphones,
  History,
  LayoutDashboard,
  Package,
  Settings,
  ShoppingCart,
  Truck,
  Users,
} from "lucide-react";

export interface DashboardNavItem {
  href: string;
  label: string;
  mobileLabel?: string;
  icon: LucideIcon;
  feature: string | null;
  permission: string | null;
  mobile?: boolean;
}

export const DASHBOARD_NAV_ITEMS: DashboardNavItem[] = [
  {
    href: "/dashboard",
    label: "Dashboard",
    mobileLabel: "Home",
    icon: LayoutDashboard,
    feature: null,
    permission: "dashboard.view",
    mobile: true,
  },
  {
    href: "/pos",
    label: "POS",
    icon: ShoppingCart,
    feature: null,
    permission: "pos.create",
    mobile: true,
  },
  {
    href: "/kitchen",
    label: "Dapur (KDS)",
    mobileLabel: "Dapur",
    icon: ChefHat,
    feature: "order",
    permission: "kitchen.view",
    mobile: true,
  },
  {
    href: "/reservations",
    label: "Reservasi",
    icon: CalendarDays,
    feature: "reservation",
    permission: "reservation.view",
  },
  {
    href: "/delivery",
    label: "Delivery",
    icon: Truck,
    feature: "delivery",
    permission: "delivery.view",
  },
  {
    href: "/inventory",
    label: "Inventori",
    mobileLabel: "Stok",
    icon: Package,
    feature: null,
    permission: "inventory.view",
    mobile: true,
  },
  {
    href: "/members",
    label: "Member",
    icon: Users,
    feature: "loyalty",
    permission: "loyalty.view",
    mobile: true,
  },
  {
    href: "/crm",
    label: "CRM",
    icon: Headphones,
    feature: "crm",
    permission: "crm.view",
  },
  {
    href: "/reports",
    label: "Laporan",
    icon: BarChart3,
    feature: "report",
    permission: "report.view",
    mobile: true,
  },
  {
    href: "/pos/history",
    label: "Riwayat POS",
    icon: History,
    feature: null,
    permission: "pos.view",
  },
  {
    href: "/settings",
    label: "Pengaturan",
    mobileLabel: "Atur",
    icon: Settings,
    feature: null,
    permission: "tenant.settings.view",
    mobile: true,
  },
];