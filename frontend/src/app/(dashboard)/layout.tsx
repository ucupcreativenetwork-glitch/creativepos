"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  BarChart3,
  CalendarDays,
  ChefHat,
  Headphones,
  History,
  LayoutDashboard,
  LogOut,
  Package,
  Settings,
  Shield,
  ShoppingCart,
  Store,
  Truck,
  Users,
} from "lucide-react";
import { useMutation } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { cn } from "@/lib/utils/cn";
import { getInitials } from "@/lib/utils/format";
import { logout } from "@/lib/api/auth";
import { useAuthStore } from "@/stores/auth-store";
import { Button } from "@/components/ui/button";
import { OnboardingGate } from "@/components/onboarding/onboarding-gate";
import { MobileBottomNav } from "@/components/layout/mobile-bottom-nav";
import { NotificationBell } from "@/components/notifications/notification-bell";
import { usePackageFeatures } from "@/hooks/usePackageFeatures";

const baseNavItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard, feature: null },
  { href: "/pos", label: "POS", icon: ShoppingCart, feature: null },
  { href: "/kitchen", label: "Dapur (KDS)", icon: ChefHat, feature: "order" },
  { href: "/reservations", label: "Reservasi", icon: CalendarDays, feature: "reservation" },
  { href: "/delivery", label: "Delivery", icon: Truck, feature: "delivery" },
  { href: "/inventory", label: "Inventori", icon: Package, feature: null },
  { href: "/members", label: "Member", icon: Users, feature: "loyalty" },
  { href: "/crm", label: "CRM", icon: Headphones, feature: "crm" },
  { href: "/reports", label: "Laporan", icon: BarChart3, feature: "report" },
  { href: "/pos/history", label: "Riwayat POS", icon: History, feature: null },
  { href: "/settings", label: "Pengaturan", icon: Settings, feature: null },
];

const platformNavItem = {
  href: "/platform",
  label: "Platform",
  icon: Shield,
};

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, tenant, clearAuth } = useAuthStore();
  const { hasFeature } = usePackageFeatures();

  const navItems = (user?.is_super_admin
    ? [...baseNavItems, { ...platformNavItem, feature: null }]
    : baseNavItems
  ).filter((item) => !item.feature || hasFeature(item.feature));

  const logoutMutation = useMutation({
    mutationFn: logout,
    onSuccess: () => {
      clearAuth();
      toast.success("Berhasil keluar");
      router.push("/login");
    },
    onError: () => {
      clearAuth();
      router.push("/login");
    },
  });

  return (
    <div className="flex min-h-screen bg-slate-50">
      <OnboardingGate />
      <aside className="hidden w-64 flex-col border-r border-border bg-white md:flex">
        <div className="flex h-16 items-center justify-between gap-2.5 border-b border-border px-6">
          <div className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-primary-foreground">
              <Store className="h-4 w-4" />
            </div>
            <div>
              <p className="text-sm font-bold leading-tight">CreativePOS</p>
              <p className="text-[10px] text-muted-foreground">Creative Network</p>
            </div>
          </div>
          <NotificationBell />
        </div>

        {tenant && (
          <div className="border-b border-border px-4 py-3">
            <p className="truncate text-xs text-muted-foreground">Bisnis</p>
            <p className="truncate text-sm font-medium">{tenant.name}</p>
          </div>
        )}

        <nav className="flex-1 space-y-1 p-4">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive =
              pathname === item.href || pathname.startsWith(`${item.href}/`);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                  isActive
                    ? "bg-primary/10 text-primary"
                    : "text-muted-foreground hover:bg-slate-100 hover:text-foreground"
                )}
              >
                <Icon className="h-4 w-4" />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-border p-4">
          {user && (
            <div className="mb-3 flex items-center gap-3">
              <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-sm font-semibold text-primary">
                {getInitials(user.name)}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{user.name}</p>
                <p className="truncate text-xs text-muted-foreground">
                  {user.email}
                </p>
              </div>
            </div>
          )}
          <Button
            variant="outline"
            size="sm"
            className="w-full"
            onClick={() => logoutMutation.mutate()}
            isLoading={logoutMutation.isPending}
          >
            <LogOut className="h-4 w-4" />
            Keluar
          </Button>
        </div>
      </aside>

      <div className="flex flex-1 flex-col">
        <header className="flex h-16 items-center justify-between border-b border-border bg-white px-4 md:hidden">
          <div className="flex items-center gap-2">
            <Store className="h-5 w-5 text-primary" />
            <span className="font-bold">CreativePOS</span>
          </div>
          <div className="flex items-center gap-1">
            <NotificationBell />
            <Button
              variant="ghost"
              size="sm"
              onClick={() => logoutMutation.mutate()}
            >
              <LogOut className="h-4 w-4" />
            </Button>
          </div>
        </header>

        <main className="flex-1 p-4 pb-24 md:p-6 md:pb-6">{children}</main>
      </div>
      <MobileBottomNav />
    </div>
  );
}