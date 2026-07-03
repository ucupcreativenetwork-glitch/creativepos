"use client";

import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowRight, ChefHat, Clock, Flame, Utensils } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getOutlets } from "@/lib/api/dashboard";
import { bumpOrder, getKitchenQueue } from "@/lib/api/orders";
import { getErrorMessage } from "@/lib/api/client";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import type { Order } from "@/types/order";

const columns = [
  { key: "pending", label: "Menunggu", icon: Clock, color: "border-amber-200 bg-amber-50" },
  { key: "cooking", label: "Memasak", icon: Flame, color: "border-orange-200 bg-orange-50" },
  { key: "ready", label: "Siap", icon: Utensils, color: "border-emerald-200 bg-emerald-50" },
] as const;

function OrderCard({
  order,
  onBump,
  isLoading,
}: {
  order: Order;
  onBump: () => void;
  isLoading: boolean;
}) {
  return (
    <div className="rounded-lg border border-border bg-white p-3 shadow-sm">
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="font-semibold">{order.order_number}</p>
          <p className="text-xs text-muted-foreground">
            {order.table
              ? `Meja ${order.table.table_number}`
              : order.source === "qr_menu"
                ? "QR Menu"
                : order.source}
          </p>
        </div>
        <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium capitalize">
          {order.status}
        </span>
      </div>

      <div className="mt-2 space-y-1">
        {order.items?.map((item) => (
          <div key={item.id} className="flex justify-between text-sm">
            <span>
              {item.quantity}x {item.product_name}
            </span>
          </div>
        ))}
      </div>

      {order.notes && (
        <p className="mt-2 text-xs italic text-muted-foreground">{order.notes}</p>
      )}

      <div className="mt-3 flex items-center justify-between border-t border-border pt-2">
        <span className="text-sm font-medium">{formatCurrency(order.subtotal)}</span>
        <span className="text-[10px] text-muted-foreground">
          {order.created_at
            ? formatDate(order.created_at, {
                hour: "2-digit",
                minute: "2-digit",
              })
            : ""}
        </span>
      </div>

      {order.status !== "served" && (
        <Button
          size="sm"
          className="mt-3 w-full"
          onClick={onBump}
          isLoading={isLoading}
        >
          <ArrowRight className="h-4 w-4" />
          {order.status === "pending"
            ? "Mulai Masak"
            : order.status === "cooking"
              ? "Siap"
              : "Sajikan"}
        </Button>
      )}
    </div>
  );
}

export default function KitchenPage() {
  const queryClient = useQueryClient();

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const [selectedOutletId, setSelectedOutletId] = useState<number | undefined>();

  useEffect(() => {
    if (outlets.length === 0) return;

    const stored = localStorage.getItem("kitchen_outlet_id");
    const storedId = stored ? Number(stored) : undefined;
    const validStored = outlets.some((o) => o.id === storedId);

    setSelectedOutletId(
      validStored && storedId ? storedId : outlets[0]?.id
    );
  }, [outlets]);

  const outletId = selectedOutletId;

  const { data: orders = [], isLoading } = useQuery({
    queryKey: ["kitchen", "queue", outletId],
    queryFn: () => getKitchenQueue(outletId),
    enabled: !!outletId,
    refetchInterval: 10_000,
  });

  const bumpMutation = useMutation({
    mutationFn: bumpOrder,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["kitchen"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const grouped = useMemo(() => {
    const map: Record<string, Order[]> = {
      pending: [],
      cooking: [],
      ready: [],
    };

    for (const order of orders) {
      if (map[order.status]) {
        map[order.status].push(order);
      }
    }

    return map;
  }, [orders]);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="flex items-center gap-2 text-2xl font-bold tracking-tight">
            <ChefHat className="h-7 w-7 text-primary" />
            Kitchen Display (KDS)
          </h1>
          <p className="mt-1 text-muted-foreground">
            Antrian pesanan dapur — refresh otomatis 10 detik
          </p>
        </div>
        <div className="flex items-center gap-2">
          {outlets.length > 1 && (
            <select
              value={outletId ?? ""}
              onChange={(e) => {
                const id = Number(e.target.value);
                setSelectedOutletId(id);
                localStorage.setItem("kitchen_outlet_id", String(id));
              }}
              className="h-9 rounded-lg border border-border bg-white px-3 text-sm"
            >
              {outlets.map((outlet) => (
                <option key={outlet.id} value={outlet.id}>
                  {outlet.name}
                </option>
              ))}
            </select>
          )}
          <div className="rounded-lg bg-slate-100 px-3 py-1.5 text-sm font-medium">
            {orders.length} pesanan aktif
          </div>
        </div>
      </div>

      {isLoading ? (
        <div className="grid gap-4 lg:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="h-64 animate-pulse rounded-xl bg-slate-100" />
          ))}
        </div>
      ) : (
        <div className="grid gap-4 lg:grid-cols-3">
          {columns.map((col) => {
            const Icon = col.icon;
            const items = grouped[col.key] ?? [];

            return (
              <Card key={col.key} className={col.color}>
                <CardHeader className="pb-2">
                  <CardTitle className="flex items-center gap-2 text-base">
                    <Icon className="h-4 w-4" />
                    {col.label}
                    <span className="ml-auto rounded-full bg-white px-2 py-0.5 text-xs font-bold">
                      {items.length}
                    </span>
                  </CardTitle>
                </CardHeader>
                <CardContent className="space-y-3">
                  {items.length === 0 ? (
                    <p className="py-8 text-center text-sm text-muted-foreground">
                      Kosong
                    </p>
                  ) : (
                    items.map((order) => (
                      <OrderCard
                        key={order.uuid}
                        order={order}
                        onBump={() => bumpMutation.mutate(order.uuid)}
                        isLoading={
                          bumpMutation.isPending &&
                          bumpMutation.variables === order.uuid
                        }
                      />
                    ))
                  )}
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}