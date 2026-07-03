"use client";

import { useEffect, useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { useOfflineQueue } from "@/hooks/useOfflineQueue";
import { useProductCache } from "@/hooks/useProductCache";
import { getOutlets } from "@/lib/api/dashboard";
import { getCurrentShift, type HeldTransactionResume } from "@/lib/api/pos";
import { getTenantSettings } from "@/lib/api/settings";
import { findProductByScanCode } from "@/lib/offline/product-cache-store";
import { usePosStore } from "@/stores/pos-store";
import type { PosProduct, PosTransaction } from "@/types/pos";

export function usePosSession() {
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

  const handlePaymentSuccess = (txNumber: string) => {
    setLastReceipt(txNumber);
    clearCart();
    refresh();
    refetchShift();
  };

  const handleShiftSuccess = () => {
    refetchShift();
    refresh();
  };

  return {
    search,
    setSearch,
    categoryId,
    setCategoryId,
    paymentOpen,
    setPaymentOpen,
    shiftDialog,
    setShiftDialog,
    lastReceipt,
    modifierProduct,
    setModifierProduct,
    syncedReceipt,
    setSyncedReceipt,
    heldPanelOpen,
    setHeldPanelOpen,
    outlets,
    outletId,
    outletName,
    handleOutletChange,
    products,
    categories,
    paymentMethods,
    catalog,
    productsLoading,
    fromCache,
    isOnline,
    catalogError,
    refreshCatalog,
    pendingCount,
    failedCount,
    isSyncing,
    enqueue,
    syncNow,
    shift,
    refetchShift,
    taxRate,
    serviceRate,
    items,
    removeItem,
    updateQuantity,
    clearCart,
    addItemWithModifiers,
    itemCount,
    cartSubtotal,
    taxAmount,
    serviceAmount,
    grandTotal,
    refresh,
    handlePay,
    handleResumeHeld,
    handleProductClick,
    handleBarcodeScan,
    handlePaymentSuccess,
    handleShiftSuccess,
  };
}