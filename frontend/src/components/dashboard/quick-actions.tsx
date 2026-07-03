import Link from "next/link";
import {
  Package,
  PlusCircle,
  Settings,
  ShoppingCart,
} from "lucide-react";
import { cn } from "@/lib/utils/cn";

const actions = [
  {
    href: "/pos",
    label: "Buka POS",
    description: "Mulai transaksi",
    icon: ShoppingCart,
    color: "bg-emerald-50 text-emerald-700 hover:bg-emerald-100",
  },
  {
    href: "/inventory",
    label: "Tambah Produk",
    description: "Kelola menu & stok",
    icon: Package,
    color: "bg-blue-50 text-blue-700 hover:bg-blue-100",
  },
  {
    href: "/settings",
    label: "Pengaturan",
    description: "Outlet & pembayaran",
    icon: Settings,
    color: "bg-violet-50 text-violet-700 hover:bg-violet-100",
  },
  {
    href: "/inventory",
    label: "Inventori",
    description: "Lihat semua produk",
    icon: PlusCircle,
    color: "bg-amber-50 text-amber-700 hover:bg-amber-100",
  },
];

export function QuickActions() {
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
      {actions.map((action) => {
        const Icon = action.icon;

        return (
          <Link
            key={action.label}
            href={action.href}
            className={cn(
              "group flex flex-col gap-2 rounded-xl border border-transparent p-4 transition-all hover:border-border hover:shadow-sm",
              action.color
            )}
          >
            <Icon className="h-5 w-5 transition-transform group-hover:scale-110" />
            <div>
              <p className="text-sm font-semibold">{action.label}</p>
              <p className="text-xs opacity-80">{action.description}</p>
            </div>
          </Link>
        );
      })}
    </div>
  );
}