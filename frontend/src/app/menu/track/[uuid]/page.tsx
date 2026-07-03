"use client";

import { use } from "react";
import { useQuery } from "@tanstack/react-query";
import { CheckCircle, Clock, Flame, Utensils } from "lucide-react";
import { trackOrder } from "@/lib/api/public-menu";
import { formatCurrency, formatDate } from "@/lib/utils/format";

const statusSteps = [
  { key: "pending", label: "Diterima", icon: Clock },
  { key: "cooking", label: "Dimasak", icon: Flame },
  { key: "ready", label: "Siap", icon: Utensils },
  { key: "served", label: "Disajikan", icon: CheckCircle },
];

export default function TrackOrderPage({
  params,
}: {
  params: Promise<{ uuid: string }>;
}) {
  const { uuid } = use(params);

  const { data: order, isLoading } = useQuery({
    queryKey: ["track-order", uuid],
    queryFn: () => trackOrder(uuid),
    refetchInterval: 10_000,
  });

  if (isLoading || !order) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  const currentIdx = statusSteps.findIndex((s) => s.key === order.status);

  return (
    <div className="min-h-screen bg-slate-50 p-6">
      <div className="mx-auto max-w-md">
        <h1 className="text-xl font-bold">Lacak Pesanan</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {order.order_number}
        </p>

        <div className="mt-8 flex justify-between">
          {statusSteps.map((step, idx) => {
            const Icon = step.icon;
            const active = idx <= currentIdx;

            return (
              <div key={step.key} className="flex flex-col items-center gap-2">
                <div
                  className={`flex h-10 w-10 items-center justify-center rounded-full ${
                    active
                      ? "bg-primary text-primary-foreground"
                      : "bg-slate-200 text-slate-400"
                  }`}
                >
                  <Icon className="h-5 w-5" />
                </div>
                <span
                  className={`text-xs font-medium ${
                    active ? "text-primary" : "text-muted-foreground"
                  }`}
                >
                  {step.label}
                </span>
              </div>
            );
          })}
        </div>

        <div className="mt-8 rounded-xl bg-white p-4 shadow-sm">
          <p className="text-sm font-medium">Detail Pesanan</p>
          <div className="mt-3 space-y-2">
            {order.items.map((item, i) => (
              <div key={i} className="flex justify-between text-sm">
                <span>
                  {item.product_name} x{item.quantity}
                </span>
                <span className="capitalize text-muted-foreground">
                  {item.status}
                </span>
              </div>
            ))}
          </div>
          <div className="mt-4 flex justify-between border-t border-border pt-3 font-semibold">
            <span>Total</span>
            <span>{formatCurrency(order.subtotal)}</span>
          </div>
        </div>

        {order.updated_at && (
          <p className="mt-4 text-center text-xs text-muted-foreground">
            Terakhir diperbarui:{" "}
            {formatDate(order.updated_at, {
              day: "numeric",
              month: "short",
              hour: "2-digit",
              minute: "2-digit",
            })}
          </p>
        )}
      </div>
    </div>
  );
}