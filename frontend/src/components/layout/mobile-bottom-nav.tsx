"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  BarChart3,
  ChefHat,
  LayoutDashboard,
  Package,
  Settings,
  ShoppingCart,
  Users,
} from "lucide-react";
import { cn } from "@/lib/utils/cn";

const mobileNavItems = [
  { href: "/dashboard", label: "Home", icon: LayoutDashboard },
  { href: "/pos", label: "POS", icon: ShoppingCart },
  { href: "/inventory", label: "Stok", icon: Package },
  { href: "/members", label: "Member", icon: Users },
  { href: "/kitchen", label: "Dapur", icon: ChefHat },
  { href: "/reports", label: "Laporan", icon: BarChart3 },
  { href: "/settings", label: "Atur", icon: Settings },
];

export function MobileBottomNav() {
  const pathname = usePathname();

  return (
    <nav className="fixed inset-x-0 bottom-0 z-40 border-t border-border bg-white/95 backdrop-blur md:hidden">
      <div className="mx-auto flex h-16 max-w-lg items-stretch justify-around overflow-x-auto px-1 pb-[env(safe-area-inset-bottom)]">
        {mobileNavItems.map((item) => {
          const Icon = item.icon;
          const isActive =
            pathname === item.href || pathname.startsWith(`${item.href}/`);

          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex min-w-[3.5rem] shrink-0 flex-col items-center justify-center gap-0.5 rounded-lg px-1 py-2 text-[10px] font-medium transition-colors",
                isActive
                  ? "text-primary"
                  : "text-muted-foreground hover:text-foreground"
              )}
            >
              <Icon
                className={cn(
                  "h-5 w-5",
                  isActive && "scale-110 transition-transform"
                )}
              />
              <span className="truncate">{item.label}</span>
              {isActive && (
                <span className="h-0.5 w-5 rounded-full bg-primary" />
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}