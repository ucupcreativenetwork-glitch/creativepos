"use client";

import type { Outlet } from "@/types/dashboard";

interface OutletSelectorProps {
  outlets: Outlet[];
  value?: number;
  onChange: (outletId: number | undefined) => void;
}

export function OutletSelector({
  outlets,
  value,
  onChange,
}: OutletSelectorProps) {
  if (outlets.length <= 1) return null;

  return (
    <select
      value={value ?? ""}
      onChange={(e) =>
        onChange(e.target.value ? Number(e.target.value) : undefined)
      }
      className="h-9 rounded-lg border border-border bg-white px-3 text-sm shadow-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
    >
      <option value="">Semua Outlet</option>
      {outlets.map((outlet) => (
        <option key={outlet.id} value={outlet.id}>
          {outlet.name} ({outlet.code})
        </option>
      ))}
    </select>
  );
}