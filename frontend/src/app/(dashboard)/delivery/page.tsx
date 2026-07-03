"use client";

import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ArrowRight,
  Clock,
  Flame,
  MapPin,
  Package,
  Plus,
  Truck,
  Utensils,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getOutlets } from "@/lib/api/dashboard";
import { getErrorMessage } from "@/lib/api/client";
import {
  assignDriver,
  calculateFee,
  createDeliveryOrder,
  getDeliveryOrders,
  getDrivers,
  getZones,
  updateDeliveryStatus,
} from "@/lib/api/delivery";
import { getPosProducts } from "@/lib/api/pos";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import { DeliverySetupPanel } from "@/components/delivery/delivery-setup-panel";
import { QueryErrorState } from "@/components/ui/query-error-state";
import type {
  DeliveryOrder,
  DeliveryStatus,
  FeeCalculation,
} from "@/types/delivery";
import type { PosProduct } from "@/types/pos";

const columns = [
  {
    key: "waiting",
    label: "Menunggu",
    icon: Clock,
    color: "border-slate-200 bg-slate-50",
  },
  {
    key: "processing",
    label: "Diproses",
    icon: Package,
    color: "border-blue-200 bg-blue-50",
  },
  {
    key: "cooking",
    label: "Memasak",
    icon: Flame,
    color: "border-orange-200 bg-orange-50",
  },
  {
    key: "ready",
    label: "Siap",
    icon: Utensils,
    color: "border-emerald-200 bg-emerald-50",
  },
  {
    key: "delivering",
    label: "Dikirim",
    icon: Truck,
    color: "border-violet-200 bg-violet-50",
  },
] as const;

const nextStatus: Partial<Record<DeliveryStatus, DeliveryStatus>> = {
  waiting: "processing",
  processing: "cooking",
  cooking: "ready",
  ready: "delivering",
  delivering: "completed",
};

const advanceLabels: Partial<Record<DeliveryStatus, string>> = {
  waiting: "Proses",
  processing: "Mulai Masak",
  cooking: "Siap",
  ready: "Kirim",
  delivering: "Selesai",
};

const statusLabels: Record<DeliveryStatus, string> = {
  waiting: "Menunggu",
  processing: "Diproses",
  cooking: "Memasak",
  ready: "Siap",
  delivering: "Dikirim",
  completed: "Selesai",
  cancelled: "Dibatalkan",
};

interface CartLine {
  product: PosProduct;
  quantity: number;
}

function DeliveryOrderCard({
  order,
  onSelect,
  onAdvance,
  isAdvancing,
}: {
  order: DeliveryOrder;
  onSelect: () => void;
  onAdvance: () => void;
  isAdvancing: boolean;
}) {
  const next = nextStatus[order.status];

  return (
    <div
      className="cursor-pointer rounded-lg border border-border bg-white p-3 shadow-sm transition-shadow hover:shadow-md"
      onClick={onSelect}
      onKeyDown={(e) => e.key === "Enter" && onSelect()}
      role="button"
      tabIndex={0}
    >
      <div className="flex items-start justify-between gap-2">
        <div>
          <p className="font-semibold">{order.delivery_number}</p>
          <p className="text-xs text-muted-foreground">{order.customer_name}</p>
        </div>
        {order.driver && (
          <span className="rounded-full bg-violet-50 px-2 py-0.5 text-[10px] font-medium text-violet-700">
            {order.driver.name}
          </span>
        )}
      </div>

      {order.address && (
        <p className="mt-2 flex items-start gap-1 text-xs text-muted-foreground">
          <MapPin className="mt-0.5 h-3 w-3 shrink-0" />
          <span className="line-clamp-2">{order.address.address}</span>
        </p>
      )}

      <div className="mt-2 space-y-1">
        {order.items?.slice(0, 3).map((item) => (
          <div key={item.id} className="flex justify-between text-sm">
            <span>
              {item.quantity}x {item.product_name}
            </span>
          </div>
        ))}
        {(order.items?.length ?? 0) > 3 && (
          <p className="text-xs text-muted-foreground">
            +{(order.items?.length ?? 0) - 3} item lainnya
          </p>
        )}
      </div>

      <div className="mt-3 flex items-center justify-between border-t border-border pt-2">
        <span className="text-sm font-medium">
          {formatCurrency(order.grand_total ?? order.subtotal ?? 0)}
        </span>
        <span className="text-[10px] text-muted-foreground">
          Ongkir {formatCurrency(order.shipping_fee)}
        </span>
      </div>

      {next && (
        <Button
          size="sm"
          className="mt-3 w-full"
          onClick={(e) => {
            e.stopPropagation();
            onAdvance();
          }}
          isLoading={isAdvancing}
        >
          <ArrowRight className="h-4 w-4" />
          {advanceLabels[order.status]}
        </Button>
      )}
    </div>
  );
}

function CreateDeliveryDialog({
  open,
  onClose,
  onSuccess,
  defaultOutletId,
}: {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  defaultOutletId?: number;
}) {
  const [outletId, setOutletId] = useState(defaultOutletId ?? 0);
  const [customerName, setCustomerName] = useState("");
  const [customerPhone, setCustomerPhone] = useState("");
  const [address, setAddress] = useState("");
  const [zoneId, setZoneId] = useState<number | "">("");
  const [cart, setCart] = useState<CartLine[]>([]);
  const [productSearch, setProductSearch] = useState("");
  const [distanceKm, setDistanceKm] = useState("3");
  const [fee, setFee] = useState<FeeCalculation | null>(null);

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const { data: products = [] } = useQuery({
    queryKey: ["pos", "products", productSearch],
    queryFn: () => getPosProducts({ search: productSearch || undefined }),
    enabled: open,
  });

  const { data: zones = [] } = useQuery({
    queryKey: ["delivery", "zones", outletId],
    queryFn: () => getZones({ outlet_id: outletId || undefined }),
    enabled: open && !!outletId,
  });

  useEffect(() => {
    if (!open) return;
    setOutletId(defaultOutletId ?? outlets[0]?.id ?? 0);
    setCustomerName("");
    setCustomerPhone("");
    setAddress("");
    setZoneId("");
    setCart([]);
    setProductSearch("");
    setDistanceKm("3");
    setFee(null);
  }, [open, defaultOutletId, outlets]);

  const feeMutation = useMutation({
    mutationFn: calculateFee,
    onSuccess: (result) => setFee(result),
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  useEffect(() => {
    const distance = parseFloat(distanceKm) || 0;
    if (!zoneId || !outletId || distance <= 0) {
      setFee(null);
      return;
    }

    const timer = setTimeout(() => {
      feeMutation.mutate({
        zone_id: Number(zoneId),
        distance_km: distance,
      });
    }, 500);

    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [zoneId, distanceKm, outletId]);

  const createMutation = useMutation({
    mutationFn: createDeliveryOrder,
    onSuccess: () => {
      toast.success("Order delivery berhasil dibuat");
      onSuccess();
      onClose();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const subtotal = cart.reduce(
    (sum, line) => sum + line.product.base_price * line.quantity,
    0
  );

  function addProduct(product: PosProduct) {
    setCart((prev) => {
      const existing = prev.find((l) => l.product.id === product.id);
      if (existing) {
        return prev.map((l) =>
          l.product.id === product.id
            ? { ...l, quantity: l.quantity + 1 }
            : l
        );
      }
      return [...prev, { product, quantity: 1 }];
    });
  }

  function updateQty(productId: number, qty: number) {
    if (qty <= 0) {
      setCart((prev) => prev.filter((l) => l.product.id !== productId));
      return;
    }
    setCart((prev) =>
      prev.map((l) =>
        l.product.id === productId ? { ...l, quantity: qty } : l
      )
    );
  }

  function handleSubmit() {
    if (!outletId) {
      toast.error("Pilih outlet terlebih dahulu");
      return;
    }
    if (!customerName || !customerPhone) {
      toast.error("Nama dan telepon wajib diisi");
      return;
    }
    if (!address) {
      toast.error("Alamat wajib diisi");
      return;
    }
    if (cart.length === 0) {
      toast.error("Pilih minimal 1 produk");
      return;
    }

    createMutation.mutate({
      outlet_id: outletId,
      customer_name: customerName,
      customer_phone: customerPhone,
      zone_id: zoneId ? Number(zoneId) : undefined,
      distance_km: parseFloat(distanceKm) || undefined,
      shipping_fee: fee?.shipping_fee,
      estimated_minutes: fee?.estimated_minutes,
      address: {
        label: "Pengantaran",
        recipient_name: customerName,
        phone: customerPhone,
        address,
      },
      items: cart.map((l) => ({
        product_id: l.product.id,
        quantity: l.quantity,
      })),
    });
  }

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold">Buat Order Delivery</h2>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1 hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 p-6">
          <div className="space-y-2">
            <Label>Outlet</Label>
            <select
              value={outletId}
              onChange={(e) => {
                setOutletId(Number(e.target.value));
                setZoneId("");
                setFee(null);
              }}
              className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
            >
              <option value={0}>Pilih outlet</option>
              {outlets.map((o) => (
                <option key={o.id} value={o.id}>
                  {o.name}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label>Nama Penerima</Label>
              <Input
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label>Telepon</Label>
              <Input
                value={customerPhone}
                onChange={(e) => setCustomerPhone(e.target.value)}
                placeholder="08xxxxxxxxxx"
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Alamat Pengantaran</Label>
            <textarea
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              rows={2}
              className="flex w-full rounded-lg border border-border bg-white px-3 py-2 text-sm"
            />
          </div>

          <div className="space-y-2">
            <Label>Jarak (km)</Label>
            <Input
              type="number"
              min={0.1}
              step={0.1}
              value={distanceKm}
              onChange={(e) => setDistanceKm(e.target.value)}
              placeholder="Contoh: 3"
            />
          </div>

          <div className="space-y-2">
            <Label>Zona Pengantaran</Label>
            <select
              value={zoneId}
              onChange={(e) =>
                setZoneId(e.target.value ? Number(e.target.value) : "")
              }
              className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
            >
              <option value="">Pilih zona</option>
              {zones.map((z) => (
                <option key={z.id} value={z.id}>
                  {z.name} — {formatCurrency(z.base_fee)}
                </option>
              ))}
            </select>
            {feeMutation.isPending && (
              <p className="text-xs text-muted-foreground">
                Menghitung ongkir...
              </p>
            )}
            {fee && (
              <p className="text-sm font-medium text-primary">
                Ongkir: {formatCurrency(fee.shipping_fee)}
                {fee.distance_km > 0 && ` · ${fee.distance_km} km`}
                {fee.estimated_minutes && ` · ~${fee.estimated_minutes} menit`}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label>Produk</Label>
            <Input
              placeholder="Cari produk..."
              value={productSearch}
              onChange={(e) => setProductSearch(e.target.value)}
            />
            <div className="max-h-32 overflow-y-auto rounded-lg border border-border">
              {products.slice(0, 8).map((product) => (
                <button
                  key={product.id}
                  type="button"
                  onClick={() => addProduct(product)}
                  className="flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-slate-50"
                >
                  <span>{product.name}</span>
                  <span className="text-muted-foreground">
                    {formatCurrency(product.base_price)}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {cart.length > 0 && (
            <div className="space-y-2 rounded-lg border border-border p-3">
              <p className="text-sm font-medium">Keranjang</p>
              {cart.map((line) => (
                <div
                  key={line.product.id}
                  className="flex items-center justify-between text-sm"
                >
                  <span>{line.product.name}</span>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() =>
                        updateQty(line.product.id, line.quantity - 1)
                      }
                      className="h-6 w-6 rounded border text-center text-xs"
                    >
                      -
                    </button>
                    <span className="w-6 text-center">{line.quantity}</span>
                    <button
                      type="button"
                      onClick={() =>
                        updateQty(line.product.id, line.quantity + 1)
                      }
                      className="h-6 w-6 rounded border text-center text-xs"
                    >
                      +
                    </button>
                  </div>
                </div>
              ))}
              <div className="flex justify-between border-t border-border pt-2 text-sm font-medium">
                <span>Subtotal</span>
                <span>{formatCurrency(subtotal)}</span>
              </div>
              {fee && (
                <div className="flex justify-between text-sm">
                  <span>Ongkir</span>
                  <span>{formatCurrency(fee.shipping_fee)}</span>
                </div>
              )}
            </div>
          )}

          <div className="flex justify-end gap-3">
            <Button variant="outline" onClick={onClose}>
              Batal
            </Button>
            <Button onClick={handleSubmit} isLoading={createMutation.isPending}>
              Buat Order
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

function DeliveryDetailPanel({
  order,
  onClose,
  onRefresh,
}: {
  order: DeliveryOrder | null;
  onClose: () => void;
  onRefresh: () => void;
}) {
  const queryClient = useQueryClient();
  const [selectedDriver, setSelectedDriver] = useState<number | "">("");

  const { data: drivers = [] } = useQuery({
    queryKey: ["delivery", "drivers"],
    queryFn: () => getDrivers({ available_only: true }),
    enabled: !!order,
  });

  useEffect(() => {
    if (order?.driver_id) {
      setSelectedDriver(order.driver_id);
    } else {
      setSelectedDriver("");
    }
  }, [order]);

  const assignMutation = useMutation({
    mutationFn: (driverId: number) => assignDriver(order!.uuid, driverId),
    onSuccess: () => {
      toast.success("Driver berhasil ditugaskan");
      queryClient.invalidateQueries({ queryKey: ["delivery"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const statusMutation = useMutation({
    mutationFn: (status: string) => updateDeliveryStatus(order!.uuid, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["delivery"] });
      onRefresh();
      toast.success("Status diperbarui");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!order) return null;

  const next = nextStatus[order.status];

  return (
    <div className="fixed inset-y-0 right-0 z-50 w-full max-w-md border-l border-border bg-white shadow-xl">
      <div className="flex h-full flex-col">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">{order.delivery_number}</h2>
            <p className="text-sm text-muted-foreground">
              {statusLabels[order.status]}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1 hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 space-y-6 overflow-y-auto p-6">
          <div>
            <p className="text-sm font-medium">Pelanggan</p>
            <p>{order.customer_name}</p>
            <p className="text-sm text-muted-foreground">{order.customer_phone}</p>
          </div>

          {(order.address?.address || order.delivery_address) && (
            <div>
              <p className="text-sm font-medium">Alamat</p>
              <p className="text-sm text-muted-foreground">
                {order.address?.address ?? order.delivery_address}
              </p>
            </div>
          )}

          <div>
            <p className="mb-2 text-sm font-medium">Item Pesanan</p>
            <div className="space-y-2">
              {order.items?.map((item) => (
                <div
                  key={item.id}
                  className="flex justify-between text-sm"
                >
                  <span>
                    {item.quantity}x {item.product_name}
                  </span>
                  <span>{formatCurrency(item.subtotal)}</span>
                </div>
              ))}
            </div>
            <div className="mt-3 space-y-1 border-t border-border pt-3 text-sm">
              <div className="flex justify-between">
                <span>Ongkir</span>
                <span>{formatCurrency(order.shipping_fee)}</span>
              </div>
              <div className="flex justify-between font-medium">
                <span>Total</span>
                <span>
                  {formatCurrency(
                    order.grand_total ??
                      (order.subtotal ?? 0) + order.shipping_fee
                  )}
                </span>
              </div>
            </div>
          </div>

          {order.created_at && (
            <p className="text-xs text-muted-foreground">
              Dibuat{" "}
              {formatDate(order.created_at, {
                day: "numeric",
                month: "short",
                hour: "2-digit",
                minute: "2-digit",
              })}
            </p>
          )}

          {["ready", "delivering"].includes(order.status) && (
            <div className="space-y-2">
              <Label>Assign Driver</Label>
              <select
                value={selectedDriver}
                onChange={(e) =>
                  setSelectedDriver(
                    e.target.value ? Number(e.target.value) : ""
                  )
                }
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="">Pilih driver</option>
                {drivers.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.name}
                    {d.vehicle_type ? ` (${d.vehicle_type})` : ""}
                    {!d.is_available ? " — Sibuk" : ""}
                  </option>
                ))}
              </select>
              <Button
                size="sm"
                className="w-full"
                disabled={!selectedDriver}
                onClick={() => assignMutation.mutate(Number(selectedDriver))}
                isLoading={assignMutation.isPending}
              >
                <Truck className="h-4 w-4" />
                Tugaskan Driver
              </Button>
            </div>
          )}
        </div>

        <div className="space-y-2 border-t border-border p-6">
          {next && (
            <Button
              className="w-full"
              onClick={() => statusMutation.mutate(next)}
              isLoading={statusMutation.isPending}
            >
              <ArrowRight className="h-4 w-4" />
              {advanceLabels[order.status]}
            </Button>
          )}
          {!["completed", "cancelled"].includes(order.status) && (
            <Button
              variant="outline"
              className="w-full text-red-600"
              onClick={() => {
                if (
                  !window.confirm(
                    `Batalkan order ${order.delivery_number}? Tindakan ini tidak dapat dibatalkan.`
                  )
                ) {
                  return;
                }
                statusMutation.mutate("cancelled");
              }}
              isLoading={statusMutation.isPending}
            >
              Batalkan Order
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}

export default function DeliveryPage() {
  const queryClient = useQueryClient();
  const [view, setView] = useState<"board" | "setup">("board");
  const [formOpen, setFormOpen] = useState(false);
  const [selectedOrder, setSelectedOrder] = useState<DeliveryOrder | null>(null);
  const [outletFilter, setOutletFilter] = useState<number | "">("");

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const outletId = outletFilter ? Number(outletFilter) : undefined;

  const {
    data: ordersData,
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["delivery", "orders", outletId ?? "all"],
    queryFn: () =>
      getDeliveryOrders({
        outlet_id: outletId,
        per_page: 100,
      }),
    enabled: view === "board",
    refetchInterval: 15_000,
  });

  const orders = ordersData?.data ?? [];

  const advanceMutation = useMutation({
    mutationFn: ({ uuid, status }: { uuid: string; status: string }) =>
      updateDeliveryStatus(uuid, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["delivery"] });
      toast.success("Status diperbarui");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const grouped = useMemo(() => {
    const map: Record<string, DeliveryOrder[]> = {
      waiting: [],
      processing: [],
      cooking: [],
      ready: [],
      delivering: [],
    };

    for (const order of orders) {
      if (map[order.status]) {
        map[order.status].push(order);
      }
    }

    return map;
  }, [orders]);

  const activeCount = orders.filter(
    (o) => !["completed", "cancelled"].includes(o.status)
  ).length;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="flex items-center gap-2 text-2xl font-bold tracking-tight">
            <Truck className="h-7 w-7 text-primary" />
            Delivery
          </h1>
          <p className="mt-1 text-muted-foreground">
            Kelola order pengantaran — refresh otomatis 15 detik
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex rounded-lg border border-border bg-white p-1">
            <button
              type="button"
              onClick={() => setView("board")}
              className={`rounded-md px-3 py-1.5 text-sm font-medium ${
                view === "board"
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground"
              }`}
            >
              Board
            </button>
            <button
              type="button"
              onClick={() => setView("setup")}
              className={`rounded-md px-3 py-1.5 text-sm font-medium ${
                view === "setup"
                  ? "bg-primary text-primary-foreground"
                  : "text-muted-foreground"
              }`}
            >
              Setup
            </button>
          </div>
          <select
            value={outletFilter}
            onChange={(e) =>
              setOutletFilter(e.target.value ? Number(e.target.value) : "")
            }
            className="h-10 rounded-lg border border-border bg-white px-3 text-sm"
          >
            <option value="">Semua Outlet</option>
            {outlets.map((o) => (
              <option key={o.id} value={o.id}>
                {o.name}
              </option>
            ))}
          </select>
          <div className="rounded-lg bg-slate-100 px-3 py-1.5 text-sm font-medium">
            {activeCount} order aktif
          </div>
          {view === "board" && (
            <Button onClick={() => setFormOpen(true)}>
              <Plus className="h-4 w-4" />
              Buat Order
            </Button>
          )}
        </div>
      </div>

      {view === "setup" ? (
        <DeliverySetupPanel />
      ) : isError ? (
        <QueryErrorState
          message={getErrorMessage(error)}
          onRetry={() => void refetch()}
        />
      ) : isLoading ? (
        <div className="grid gap-4 lg:grid-cols-5">
          {Array.from({ length: 5 }).map((_, i) => (
            <div
              key={i}
              className="h-64 animate-pulse rounded-xl bg-slate-100"
            />
          ))}
        </div>
      ) : (
        <div className="grid gap-4 lg:grid-cols-5">
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
                      <DeliveryOrderCard
                        key={order.uuid}
                        order={order}
                        onSelect={() => setSelectedOrder(order)}
                        onAdvance={() => {
                          const next = nextStatus[order.status];
                          if (next) {
                            advanceMutation.mutate({
                              uuid: order.uuid,
                              status: next,
                            });
                          }
                        }}
                        isAdvancing={
                          advanceMutation.isPending &&
                          advanceMutation.variables?.uuid === order.uuid
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

      <CreateDeliveryDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSuccess={() => refetch()}
        defaultOutletId={outletId}
      />

      <DeliveryDetailPanel
        order={selectedOrder}
        onClose={() => setSelectedOrder(null)}
        onRefresh={() => refetch()}
      />
    </div>
  );
}