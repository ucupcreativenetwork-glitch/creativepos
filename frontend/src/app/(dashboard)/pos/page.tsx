"use client";

import { useEffect, useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Clock,
  Minus,
  Plus,
  Receipt,
  Search,
  ShoppingCart,
  Package,
  Store,
  Trash2,
} from "lucide-react";
import { toast } from "sonner";
import { OfflineIndicator } from "@/components/pos/offline-indicator";
import { HeldTransactionsPanel } from "@/components/pos/held-transactions-panel";
import { PaymentDialog } from "@/components/pos/payment-dialog";
import { ProductModifierModal } from "@/components/pos/product-modifier-modal";
import { ShiftDialog } from "@/components/pos/shift-dialog";
import { SyncedReceiptDialog } from "@/components/pos/synced-receipt-dialog";
import { EmptyState } from "@/components/ui/empty-state";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useOfflineQueue } from "@/hooks/useOfflineQueue";
import { useProductCache } from "@/hooks/useProductCache";
import { getOutlets } from "@/lib/api/dashboard";
import { getCurrentShift, type HeldTransactionResume } from "@/lib/api/pos";
import { getTenantSettings } from "@/lib/api/settings";
import { findProductByScanCode } from "@/lib/offline/product-cache-store";
import { formatCurrency } from "@/lib/utils/format";
import { resolveMediaUrl } from "@/lib/utils/media";
import { usePosStore } from "@/stores/pos-store";
import type { PosProduct, PosTransaction } from "@/types/pos";

export default function PosPage() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [categoryId, setCategoryId] = useState<number | undefined>();
  const [paymentOpen, setPaymentOpen] = useState(false);
  const [shiftDialog, setShiftDialog] = useState<"open" | "close" | null>(null);
  const [lastReceipt, setLastReceipt] = useState<string | null>(null);
  const [modifierProduct, setModifierProduct] = useState<PosProduct | null>(null);
  const [syncedReceipt, setSyncedReceipt] = useState<PosTransaction | null>(null);
  const [selectedOutletId, setSelectedOutletId] = useState<number | undefined>();
  const [heldPanelOpen, setHeldPanelOpen] = useState(false);

  const {
    items,
    addItem,
    addItemWithModifiers,
    removeItem,
    updateQuantity,
    clearCart,
    subtotal,
    itemCount,
  } = usePosStore();

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  useEffect(() => {
    if (outlets.length === 0) return;

    const stored = localStorage.getItem("pos_outlet_id");
    const storedId = stored ? Number(stored) : undefined;
    const validStored = outlets.some((o) => o.id === storedId);

    setSelectedOutletId(
      validStored && storedId ? storedId : outlets[0]?.id
    );
  }, [outlets]);

  const outletId = selectedOutletId;
  const outletName = outlets.find((o) => o.id === outletId)?.name;

  const handleOutletChange = (id: number) => {
    if (id !== selectedOutletId && items.length > 0) {
      const confirmed = window.confirm(
        "Ganti outlet akan mengosongkan keranjang. Lanjutkan?"
      );
      if (!confirmed) return;
      clearCart();
    }
    setSelectedOutletId(id);
    localStorage.setItem("pos_outlet_id", String(id));
  };

  const {
    products,
    categories,
    paymentMethods,
    catalog,
    isLoading: productsLoading,
    fromCache,
    isOnline,
    error: catalogError,
    refresh: refreshCatalog,
  } = useProductCache({
    outletId,
    search,
    categoryId,
  });

  const {
    pendingCount,
    failedCount,
    isSyncing,
    enqueue,
    syncNow,
  } = useOfflineQueue({
    autoSync: true,
    onSynced: (result) => {
      if (result.syncedReceipts.length > 0) {
        setSyncedReceipt(result.syncedReceipts[result.syncedReceipts.length - 1]);
      }
      queryClient.invalidateQueries({ queryKey: ["pos"] });
      queryClient.invalidateQueries({ queryKey: ["dashboard"] });
    },
  });

  const { data: shift = null, refetch: refetchShift } = useQuery({
    queryKey: ["pos", "shift", outletId],
    queryFn: async () => (await getCurrentShift(outletId)) ?? null,
    enabled: !!outletId && isOnline,
    staleTime: 30 * 1000,
  });

  const { data: tenantSettings } = useQuery({
    queryKey: ["settings", "tenant"],
    queryFn: getTenantSettings,
    staleTime: 5 * 60 * 1000,
  });

  const cartSubtotal = useMemo(() => subtotal(), [items, subtotal]);
  const taxRate = tenantSettings?.tax_rate ?? 0;
  const serviceRate = tenantSettings?.service_charge_rate ?? 0;
  const taxAmount = useMemo(
    () => Math.round(cartSubtotal * taxRate) / 100,
    [cartSubtotal, taxRate]
  );
  const serviceAmount = useMemo(
    () => Math.round(cartSubtotal * serviceRate) / 100,
    [cartSubtotal, serviceRate]
  );
  const grandTotal = useMemo(
    () => cartSubtotal + taxAmount + serviceAmount,
    [cartSubtotal, taxAmount, serviceAmount]
  );

  const refresh = () => {
    void refreshCatalog();
    queryClient.invalidateQueries({ queryKey: ["pos"] });
    queryClient.invalidateQueries({ queryKey: ["dashboard"] });
    queryClient.invalidateQueries({ queryKey: ["inventory"] });
  };

  const handlePay = () => {
    if (items.length === 0) return;

    const stockIssues = items.filter(
      (item) =>
        item.product.track_stock && item.product.total_stock < item.quantity
    );
    if (stockIssues.length > 0) {
      toast.error(
        `Stok tidak mencukupi: ${stockIssues.map((i) => i.product.name).join(", ")}`
      );
      return;
    }

    if (isOnline && !shift) {
      toast.error("Buka shift terlebih dahulu sebelum transaksi.");
      setShiftDialog("open");
      return;
    }
    if (paymentMethods.length === 0) {
      toast.error("Metode pembayaran belum tersedia. Refresh katalog saat online.");
      return;
    }
    setPaymentOpen(true);
  };

  const handleResumeHeld = (data: HeldTransactionResume) => {
    clearCart();

    const missing: string[] = [];

    for (const item of data.items) {
      const product =
        products.find((p) => p.id === item.product_id) ??
        (item.product as PosProduct | undefined);

      if (!product) {
        missing.push(item.product_name ?? `Produk #${item.product_id}`);
        continue;
      }

      addItemWithModifiers(
        product,
        (item.modifiers ?? []).map((m) => ({
          modifier_id: m.modifier_id,
          group_id: 0,
          group_name: "",
          name: m.name,
          price_adjustment: m.price_adjustment,
        })),
        item.quantity
      );
    }

    if (missing.length > 0) {
      toast.warning(
        `${missing.length} item tidak dapat dimuat (produk tidak ditemukan): ${missing.join(", ")}`
      );
    }
  };

  const handleProductClick = (product: PosProduct) => {
    const outOfStock = product.track_stock && product.total_stock <= 0;

    if ((product.modifier_groups?.length ?? 0) > 0) {
      if (outOfStock) {
        toast.warning(
          `${product.name} stok habis. Tambahkan stok di Inventori sebelum bayar.`,
          { duration: 5000 }
        );
      }
      setModifierProduct(product);
      return;
    }

    addItem(product);

    if (outOfStock) {
      toast.warning(
        `${product.name} ditambahkan, tetapi stok 0. Tambahkan stok di Inventori sebelum bayar.`,
        { duration: 5000 }
      );
      return;
    }

    toast.success(`${product.name} ditambahkan ke keranjang`);
  };

  const handleBarcodeScan = () => {
    const code = search.trim();
    if (!code || !catalog?.products.length) return;

    const product = findProductByScanCode(catalog.products, code);
    if (!product) {
      toast.error(`Produk dengan kode "${code}" tidak ditemukan`);
      return;
    }

    setSearch("");
    handleProductClick(product);
  };

  if (outlets.length === 0) {
    return (
      <EmptyState
        icon={Store}
        title="Belum ada outlet"
        description="Tambahkan outlet terlebih dahulu agar POS dapat digunakan."
        actionLabel="Ke Pengaturan"
        actionHref="/settings"
      />
    );
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] flex-col gap-4 md:h-[calc(100vh-7rem)] lg:flex-row">
      <div className="flex flex-1 flex-col overflow-hidden rounded-xl border border-border bg-white">
        <div className="flex flex-col gap-3 border-b border-border p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h1 className="text-xl font-bold">POS Terminal</h1>
            {shift ? (
              <p className="text-xs text-emerald-600">
                Shift aktif: {shift.shift_number} · {shift.total_transactions} transaksi
              </p>
            ) : (
              <p className="text-xs text-amber-600">
                {isOnline ? "Belum ada shift terbuka" : "Shift tidak tersedia (offline)"}
              </p>
            )}
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {outlets.length > 1 && (
              <select
                value={outletId ?? ""}
                onChange={(e) => handleOutletChange(Number(e.target.value))}
                className="h-9 rounded-lg border border-border bg-white px-3 text-sm"
              >
                {outlets.map((outlet) => (
                  <option key={outlet.id} value={outlet.id}>
                    {outlet.name}
                  </option>
                ))}
              </select>
            )}
            <OfflineIndicator
              isOnline={isOnline}
              pendingCount={pendingCount}
              failedCount={failedCount}
              fromCache={fromCache}
              isSyncing={isSyncing}
              onSync={() => void syncNow()}
              onRefreshCache={() => void refreshCatalog()}
            />
            <Button
              variant="outline"
              size="sm"
              onClick={() => setHeldPanelOpen(true)}
            >
              <Clock className="h-4 w-4" />
              Ditahan
            </Button>
            {shift ? (
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShiftDialog("close")}
                disabled={!isOnline}
              >
                Tutup Shift
              </Button>
            ) : (
              <Button
                size="sm"
                onClick={() => setShiftDialog("open")}
                disabled={!outletId || !isOnline}
              >
                Buka Shift
              </Button>
            )}
          </div>
        </div>

        <div className="space-y-3 border-b border-border p-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Cari produk, scan barcode/SKU..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleBarcodeScan()}
              className="pl-9"
              autoFocus
            />
          </div>
          <div className="flex gap-2 overflow-x-auto pb-1">
            <button
              type="button"
              onClick={() => setCategoryId(undefined)}
              className={`shrink-0 rounded-full px-3 py-1 text-xs font-medium ${
                !categoryId
                  ? "bg-primary text-primary-foreground"
                  : "bg-slate-100 text-muted-foreground"
              }`}
            >
              Semua
            </button>
            {categories.map((cat) => (
              <button
                key={cat.id}
                type="button"
                onClick={() => setCategoryId(cat.id)}
                className={`shrink-0 rounded-full px-3 py-1 text-xs font-medium ${
                  categoryId === cat.id
                    ? "bg-primary text-primary-foreground"
                    : "bg-slate-100 text-muted-foreground"
                }`}
              >
                {cat.name}
              </button>
            ))}
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          {catalogError && (
            <p className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-700">
              {catalogError}
            </p>
          )}

          {productsLoading ? (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="h-28 animate-pulse rounded-xl bg-slate-100" />
              ))}
            </div>
          ) : products.length === 0 ? (
            <EmptyState
              icon={Package}
              title={fromCache ? "Cache kosong" : "Belum ada produk"}
              description={
                fromCache
                  ? "Refresh katalog saat online untuk memuat produk."
                  : search || categoryId
                    ? "Coba kata kunci atau kategori lain."
                    : "Tambahkan produk di inventori agar bisa dijual di POS."
              }
              actionLabel={
                fromCache
                  ? "Refresh Katalog"
                  : search || categoryId
                    ? undefined
                    : "Tambah Produk"
              }
              actionHref={
                fromCache || search || categoryId ? undefined : "/inventory"
              }
              onAction={fromCache ? () => void refreshCatalog() : undefined}
            />
          ) : (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
              {products.map((product) => {
                const outOfStock =
                  product.track_stock && product.total_stock <= 0;

                return (
                  <button
                    key={product.id}
                    type="button"
                    onClick={() => handleProductClick(product)}
                    className={`flex flex-col rounded-xl border p-3 text-left transition-colors hover:border-primary hover:bg-primary/5 ${
                      outOfStock
                        ? "border-amber-200 bg-amber-50/50 hover:border-amber-300 hover:bg-amber-50"
                        : "border-border"
                    }`}
                  >
                    {resolveMediaUrl(product.image_url) ? (
                      <div className="mb-2 aspect-square w-full overflow-hidden rounded-lg bg-slate-100">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img
                          src={resolveMediaUrl(product.image_url)}
                          alt={product.name}
                          className="h-full w-full object-cover"
                        />
                      </div>
                    ) : (
                      <div className="mb-2 flex aspect-square w-full items-center justify-center rounded-lg bg-slate-50 text-lg font-bold text-primary/40">
                        {product.name.charAt(0).toUpperCase()}
                      </div>
                    )}
                    <p className="line-clamp-2 text-sm font-medium leading-tight">
                      {product.name}
                    </p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      {product.sku}
                    </p>
                    <p className="mt-auto pt-2 text-sm font-semibold text-primary">
                      {formatCurrency(product.base_price)}
                    </p>
                    {product.track_stock && (
                      <p className={`text-[10px] font-medium ${outOfStock ? "text-amber-700" : "text-muted-foreground"}`}>
                        {outOfStock ? "Stok habis" : `Stok: ${product.total_stock}`}
                      </p>
                    )}
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      <div className="flex w-full flex-col rounded-xl border border-border bg-white lg:w-96">
        <div className="flex items-center justify-between border-b border-border p-4">
          <div className="flex items-center gap-2">
            <ShoppingCart className="h-5 w-5 text-primary" />
            <h2 className="font-semibold">Keranjang ({itemCount()})</h2>
          </div>
          {items.length > 0 && (
            <Button variant="ghost" size="sm" onClick={clearCart}>
              <Trash2 className="h-4 w-4" />
            </Button>
          )}
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          {items.length === 0 ? (
            <EmptyState
              icon={ShoppingCart}
              title="Keranjang kosong"
              description="Pilih produk dari katalog untuk memulai transaksi."
              className="border-0 bg-transparent py-8"
            />
          ) : (
            <div className="space-y-3">
              {items.map((item) => (
                <div
                  key={item.key}
                  className="flex items-center gap-3 rounded-lg border border-border p-3"
                >
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">
                      {item.product.name}
                    </p>
                    {item.modifiers.length > 0 && (
                      <ul className="mt-0.5 space-y-0.5">
                        {item.modifiers.map((modifier) => (
                          <li
                            key={modifier.modifier_id}
                            className="text-[11px] text-muted-foreground"
                          >
                            + {modifier.name}
                            {modifier.price_adjustment !== 0 && (
                              <span>
                                {" "}
                                ({modifier.price_adjustment > 0 ? "+" : ""}
                                {formatCurrency(modifier.price_adjustment)})
                              </span>
                            )}
                          </li>
                        ))}
                      </ul>
                    )}
                    <p className="text-xs text-muted-foreground">
                      {formatCurrency(item.unitPrice)}
                    </p>
                  </div>
                  <div className="flex items-center gap-1">
                    <Button
                      variant="outline"
                      size="sm"
                      className="h-7 w-7 p-0"
                      onClick={() =>
                        updateQuantity(item.key, item.quantity - 1)
                      }
                    >
                      <Minus className="h-3 w-3" />
                    </Button>
                    <span className="w-6 text-center text-sm font-medium">
                      {item.quantity}
                    </span>
                    <Button
                      variant="outline"
                      size="sm"
                      className="h-7 w-7 p-0"
                      onClick={() => {
                        const ok = updateQuantity(item.key, item.quantity + 1);
                        if (!ok) {
                          toast.error(
                            `Stok ${item.product.name} tidak mencukupi (maks. ${item.product.total_stock})`
                          );
                        }
                      }}
                    >
                      <Plus className="h-3 w-3" />
                    </Button>
                  </div>
                  <button
                    type="button"
                    onClick={() => removeItem(item.key)}
                    className="text-muted-foreground hover:text-red-500"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="space-y-3 border-t border-border p-4">
          <div className="space-y-1 text-sm">
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">Subtotal</span>
              <span>{formatCurrency(cartSubtotal)}</span>
            </div>
            {taxAmount > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Pajak ({taxRate}%)</span>
                <span>{formatCurrency(taxAmount)}</span>
              </div>
            )}
            {serviceAmount > 0 && (
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Service ({serviceRate}%)</span>
                <span>{formatCurrency(serviceAmount)}</span>
              </div>
            )}
            <div className="flex items-center justify-between font-semibold">
              <span>Total</span>
              <span>{formatCurrency(grandTotal)}</span>
            </div>
          </div>

          {lastReceipt && (
            <div className="flex items-center gap-2 rounded-lg bg-emerald-50 px-3 py-2 text-xs text-emerald-700">
              <Receipt className="h-4 w-4" />
              Transaksi {lastReceipt} berhasil
            </div>
          )}

          {pendingCount > 0 && (
            <div className="rounded-lg bg-amber-50 px-3 py-2 text-xs text-amber-800">
              {pendingCount} transaksi menunggu sinkronisasi
            </div>
          )}

          <div className="flex gap-2">
            <Button
              variant="outline"
              className="flex-1"
              disabled={items.length === 0}
              onClick={() => setHeldPanelOpen(true)}
            >
              <Clock className="h-4 w-4" />
              Tahan
            </Button>
            <Button
              className="flex-[2]"
              size="lg"
              disabled={items.length === 0 || (isOnline && !shift)}
              onClick={handlePay}
            >
              Bayar {formatCurrency(grandTotal)}
            </Button>
          </div>
        </div>
      </div>

      {outletId && (
        <>
          <ShiftDialog
            open={shiftDialog !== null}
            mode={shiftDialog ?? "open"}
            outletId={outletId}
            shift={shift}
            onClose={() => setShiftDialog(null)}
            onSuccess={() => {
              refetchShift();
              refresh();
            }}
          />

          <PaymentDialog
            open={paymentOpen}
            items={items}
            subtotal={cartSubtotal}
            taxRate={taxRate}
            serviceRate={serviceRate}
            outletId={outletId}
            outletName={outletName}
            shift={shift}
            paymentMethods={paymentMethods}
            isOnline={isOnline}
            onEnqueueOffline={enqueue}
            onClose={() => setPaymentOpen(false)}
            onSuccess={(txNumber) => {
              setLastReceipt(txNumber);
              clearCart();
              refresh();
              refetchShift();
            }}
          />

          <ProductModifierModal
            open={modifierProduct !== null}
            product={modifierProduct}
            onClose={() => setModifierProduct(null)}
            onConfirm={(modifiers) => {
              if (modifierProduct) {
                addItemWithModifiers(modifierProduct, modifiers);
              }
              setModifierProduct(null);
            }}
          />

          <SyncedReceiptDialog
            open={syncedReceipt !== null}
            transaction={syncedReceipt}
            onClose={() => setSyncedReceipt(null)}
          />

          <HeldTransactionsPanel
            open={heldPanelOpen}
            onClose={() => setHeldPanelOpen(false)}
            outletId={outletId}
            items={items}
            onHoldSuccess={clearCart}
            onResume={handleResumeHeld}
          />
        </>
      )}
    </div>
  );
}