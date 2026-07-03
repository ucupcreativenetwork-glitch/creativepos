import type { User } from "@/types/auth";

const LANDING_BY_PERMISSION: Array<{ permission: string; path: string }> = [
  { permission: "dashboard.view", path: "/dashboard" },
  { permission: "pos.create", path: "/pos" },
  { permission: "kitchen.view", path: "/kitchen" },
  { permission: "inventory.view", path: "/inventory" },
  { permission: "loyalty.view", path: "/members" },
  { permission: "crm.view", path: "/crm" },
  { permission: "report.view", path: "/reports" },
  { permission: "tenant.settings.view", path: "/settings" },
];

export function getPostLoginPath(
  user: User,
  permissions: string[] = [],
  fallback = "/dashboard",
): string {
  if (user.must_change_password) {
    return "/change-password";
  }

  if (user.is_super_admin || permissions.includes("dashboard.view")) {
    return fallback;
  }

  for (const item of LANDING_BY_PERMISSION) {
    if (permissions.includes(item.permission)) {
      return item.path;
    }
  }

  return fallback;
}