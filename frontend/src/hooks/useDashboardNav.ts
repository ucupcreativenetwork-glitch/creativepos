"use client";

import { Shield } from "lucide-react";
import { useMemo } from "react";
import { usePackageFeatures } from "@/hooks/usePackageFeatures";
import {
  DASHBOARD_NAV_ITEMS,
  type DashboardNavItem,
} from "@/lib/navigation/dashboard-nav";
import { useAuthStore } from "@/stores/auth-store";

const platformNavItem: DashboardNavItem = {
  href: "/platform",
  label: "Platform",
  icon: Shield,
  feature: null,
  permission: null,
};

export function useDashboardNav(options?: { mobileOnly?: boolean }) {
  const user = useAuthStore((s) => s.user);
  const hasPermission = useAuthStore((s) => s.hasPermission);
  const { hasFeature } = usePackageFeatures();

  const navItems = useMemo(() => {
    const items = user?.is_super_admin
      ? [...DASHBOARD_NAV_ITEMS, platformNavItem]
      : DASHBOARD_NAV_ITEMS;

    return items.filter((item) => {
      if (options?.mobileOnly && !item.mobile) {
        return false;
      }

      if (item.href === "/platform") {
        return !!user?.is_super_admin;
      }

      if (item.feature && !hasFeature(item.feature)) {
        return false;
      }

      if (item.permission && !hasPermission(item.permission)) {
        return false;
      }

      return true;
    });
  }, [user?.is_super_admin, hasFeature, hasPermission, options?.mobileOnly]);

  return navItems;
}