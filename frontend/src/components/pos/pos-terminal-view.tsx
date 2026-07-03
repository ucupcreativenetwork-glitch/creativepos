"use client";

import Link from "next/link";
import {
  Clock,
  LayoutGrid,
  Minus,
  Package,
  Plus,
  Receipt,
  Search,
  Store,
  Trash2,
} from "lucide-react";
import { EmptyState } from "@/components/ui/empty-state";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { OfflineIndicator } from "@/components/pos/offline-indicator";
import { HeldTransactionsPanel } from "@/components/pos/held-transactions-panel";
import { PaymentDialog } from "@/components/pos/payment-dialog";
import { ProductModifierModal } from "@/components/pos/product-modifier-modal";
import { ShiftDialog } from "@/components/pos/shift-dialog";
import { SyncedReceiptDialog } from "@/components/pos/synced-receipt-dialog";
import { usePosSession } from "@/hooks/usePosSession";
import { formatCurrency } from "@/lib/utils/format";
import { resolveMediaUrl } from "@/lib/utils/media";
import { toast } from "sonner";

const CATEGORY_COLORS = [
  "bg-sky-600 hover:bg-sky-500",
  "bg-violet-600 hover:bg-violet-500",
  "bg-amber-600 hover:bg-amber-500",
  "bg-rose-600 hover:bg-rose-500",
  "bg-teal-600 hover:bg-teal-500",
  "bg-indigo-600 hover:bg-indigo-500",
  "bg-orange-600 hover:bg-orange-500",
  "bg-cyan-600 hover:bg-cyan-500",
];

function categoryButtonColor(index: number) {
  return CATEGORY_COLORS[index % CATEGORY_COLORS.length];
}

export function PosTerminalView() {
  const session = usePosSession();
  const {
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
    handlePay,
    handleResumeHeld,
    handleProductClick,
    handleBarcodeScan,
    handlePaymentSuccess,
    handleShiftSuccess,
  } = session;

  if (outlets.length === 0) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-950 p-6">
        <EmptyState
          icon={Store}
          title="Belum ada outlet"
          description="Tambahkan outlet terlebih dahulu agar mesin kasir dapat digunakan."
          actionLabel="Ke Pengaturan"
          actionHref="/settings"
          className="max-w-md border-slate-700 bg-slate-900 text-white"
        />
      </div>
    );
  }

  return (
    <div className="flex h-screen flex-col overflow-hidden bg-slate-950 text-white">
      <header className="flex shrink-0 items-center justify-between gap-3 border-b border-slate-800 bg-slate-900 px-4 py-3">
        <div className="flex min-w-0 items-center gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-emerald-600 text-sm font-bold">
            Rp
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-bold tracking-wide">MESIN KASIR</p>
            <p className="truncate text-xs text-slate-400">
              {outletName ?? "CreativePOS"}
              {shift
                ? ` · Shift ${shift.shift_number}`
                : isOnline
                  ? " · Shift belum dibuka"
                  : " · Offline"}
            </p>
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-end gap-2">
          {outlets.length > 1 && (
            <select
              value={outletId ?? ""}
              onChange={(e) => handleOutletChange(Number(e.target.value))}
              className="h-9 rounded-lg border border-slate-700 bg-slate-800 px-3 text-sm text-white"
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
            className="border-slate-600 bg-slate-800 text-white hover:bg-slate-700"
            onClick={() => setHeldPanelOpen(true)}
          >
            <Clock className="h-4 w-4" />
            Ditahan
          </Button>
          {shift ? (
            <Button
              variant="outline"
              size="sm"
              className="border-slate-600 bg-slate-800 text-white hover:bg-slate-700"
              onClick={() => setShiftDialog("close")}
              disabled={!isOnline}
            >
              Tutup Shift
            </Button>
          ) : (
            <Button
              size="sm"
              className="bg-emerald-600 hover:bg-emerald-500"
              onClick={() => setShiftDialog("open")}
              disabled={!outletId || !isOnline}
            >
              Buka Shift
            </Button>
          )}
          <Link
            href="/pos"
            className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-slate-600 bg-slate-800 px-3 text-xs font-medium text-slate-200 transition-colors hover:bg-slate-700"
          >
            <LayoutGrid className="h-4 w-4" />
            <span className="hidden sm:inline">Mode Admin</span>
          </Link>
        </div>
      </header>

      <div className="flex min-h-0 flex-1 flex-col lg:flex-row">
        <section className="flex min-h-0 flex-1 flex-col border-b border-slate-800 lg:border-b-0 lg:border-r">
          <div className="space-y-3 border-b border-slate-800 p-4">
            <div className="relative">
              <Search className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-500" />
              <Input
                placeholder="Scan barcode / cari produk..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleBarcodeScan()}
                className="h-12 border-slate-700 bg-slate-900 pl-12 text-base text-white placeholder:text-slate-500"
                autoFocus
              />
            </div>
            <div className="flex gap-2 overflow-x-auto pb-1">
              <button
                type="button"
                onClick={() => setCategoryId(undefined)}
                className={`shrink-0 rounded-lg px-4 py-2 text-sm font-semibold transition-colors ${
                  !categoryId
                    ? "bg-emerald-600 text-white"
                    : "bg-slate-800 text-slate-300 hover:bg-slate-700"
                }`}
              >
                Semua
              </button>
              {categories.map((cat, index) => (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => setCategoryId(cat.id)}
                  className={`shrink-0 rounded-lg px-4 py-2 text-sm font-semibold transition-colors ${
                    categoryId === cat.id
                      ? "bg-emerald-600 text-white"
                      : `${categoryButtonColor(index)} text-white`
                  }`}
                >
                  {cat.name}
                </button>
              ))}
            </div>
          </div>

          <div className="flex-1 overflow-y-auto p-4">
            {catalogError && (
              <p className="mb-3 rounded-lg bg-red-950 px-3 py-2 text-sm text-red-300">
                {catalogError}
              </p>
            )}

            {productsLoading ? (
              <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
                {Array.from({ length: 10 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-32 animate-pulse rounded-xl bg-slate-800"
                  />
                ))}
              </div>
            ) : products.length === 0 ? (
              <EmptyState
                icon={Package}
                title={fromCache ? "Cache kosong" : "Belum ada produk"}
                description={
                  fromCache
                    ? "Refresh katalog saat online untuk memuat produk."
                    : "Tambahkan produk di inventori."
                }
                actionLabel={fromCache ? "Refresh Katalog" : undefined}
                onAction={fromCache ? () => void refreshCatalog() : undefined}
                className="border-slate-800 bg-slate-900 text-white"
              />
            ) : (
              <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4 2xl:grid-cols-5">
                {products.map((product) => {
                  const outOfStock =
                    product.track_stock && product.total_stock <= 0;

                  return (
                    <button
                      key={product.id}
                      type="button"
                      onClick={() => handleProductClick(product)}
                      className={`flex min-h-[7.5rem] flex-col rounded-xl border-2 p-3 text-left transition-transform active:scale-[0.98] ${
                        outOfStock
                          ? "border-amber-700/60 bg-amber-950/40"
                          : "border-slate-700 bg-slate-900 hover:border-emerald-600 hover:bg-slate-800"
                      }`}
                    >
                      {resolveMediaUrl(product.image_url) ? (
                        <div className="mb-2 aspect-[4/3] w-full overflow-hidden rounded-lg bg-slate-800">
                          {/* eslint-disable-next-line @next/next/no-img-element */}
                          <img
                            src={resolveMediaUrl(product.image_url)}
                            alt={product.name}
                            className="h-full w-full object-cover"
                          />
                        </div>
                      ) : (
                        <div className="mb-2 flex aspect-[4/3] w-full items-center justify-center rounded-lg bg-slate-800 text-2xl font-bold text-emerald-500/50">
                          {product.name.charAt(0).toUpperCase()}
                        </div>
                      )}
                      <p className="line-clamp-2 text-sm font-bold leading-tight">
                        {product.name}
                      </p>
                      <p className="mt-auto pt-2 font-mono text-base font-bold text-emerald-400">
                        {formatCurrency(product.base_price)}
                      </p>
                      {product.track_stock && (
                        <p
                          className={`text-[10px] font-medium ${
                            outOfStock ? "text-amber-400" : "text-slate-500"
                          }`}
                        >
                          {outOfStock ? "Stok habis" : `Stok ${product.total_stock}`}
                        </p>
                      )}
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        </section>

        <aside className="flex w-full shrink-0 flex-col bg-slate-900 lg:w-[22rem] xl:w-[26rem]">
          <div className="flex items-center justify-between border-b border-slate-800 px-4 py-3">
            <p className="text-sm font-semibold text-slate-300">
              Keranjang ({itemCount()})
            </p>
            {items.length > 0 && (
              <button
                type="button"
                onClick={clearCart}
                className="text-slate-500 transition-colors hover:text-red-400"
                aria-label="Kosongkan keranjang"
              >
                <Trash2 className="h-5 w-5" />
              </button>
            )}
          </div>

          <div className="min-h-0 flex-1 overflow-y-auto px-3 py-2">
            {items.length === 0 ? (
              <p className="py-12 text-center text-sm text-slate-500">
                Ketuk produk untuk mulai transaksi
              </p>
            ) : (
              <div className="space-y-2">
                {items.map((item) => (
                  <div
                    key={item.key}
                    className="flex items-center gap-2 rounded-lg bg-slate-800/80 px-3 py-2.5"
                  >
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-medium">
                        {item.product.name}
                      </p>
                      {item.modifiers.length > 0 && (
                        <p className="truncate text-[11px] text-slate-400">
                          {item.modifiers.map((m) => m.name).join(", ")}
                        </p>
                      )}
                      <p className="font-mono text-xs text-emerald-400/80">
                        {formatCurrency(item.unitPrice)}
                      </p>
                    </div>
                    <div className="flex items-center gap-1">
                      <button
                        type="button"
                        onClick={() =>
                          updateQuantity(item.key, item.quantity - 1)
                        }
                        className="flex h-9 w-9 items-center justify-center rounded-lg bg-slate-700 text-white hover:bg-slate-600"
                      >
                        <Minus className="h-4 w-4" />
                      </button>
                      <span className="w-7 text-center font-mono text-base font-bold">
                        {item.quantity}
                      </span>
                      <button
                        type="button"
                        onClick={() => {
                          const ok = updateQuantity(
                            item.key,
                            item.quantity + 1
                          );
                          if (!ok) {
                            toast.error(
                              `Stok ${item.product.name} tidak mencukupi`
                            );
                          }
                        }}
                        className="flex h-9 w-9 items-center justify-center rounded-lg bg-slate-700 text-white hover:bg-slate-600"
                      >
                        <Plus className="h-4 w-4" />
                      </button>
                    </div>
                    <button
                      type="button"
                      onClick={() => removeItem(item.key)}
                      className="text-slate-500 hover:text-red-400"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          <div className="border-t border-slate-800 p-4">
            <div className="mb-1 flex items-center justify-between text-xs text-slate-500">
              <span>Subtotal</span>
              <span className="font-mono">{formatCurrency(cartSubtotal)}</span>
            </div>
            {taxAmount > 0 && (
              <div className="mb-1 flex items-center justify-between text-xs text-slate-500">
                <span>Pajak ({taxRate}%)</span>
                <span className="font-mono">{formatCurrency(taxAmount)}</span>
              </div>
            )}
            {serviceAmount > 0 && (
              <div className="mb-1 flex items-center justify-between text-xs text-slate-500">
                <span>Service ({serviceRate}%)</span>
                <span className="font-mono">
                  {formatCurrency(serviceAmount)}
                </span>
              </div>
            )}

            <div className="my-3 rounded-xl bg-slate-950 px-4 py-4 ring-1 ring-slate-700">
              <p className="text-center text-xs uppercase tracking-widest text-slate-500">
                Total Bayar
              </p>
              <p className="text-center font-mono text-4xl font-bold tracking-tight text-emerald-400 xl:text-5xl">
                {formatCurrency(grandTotal)}
              </p>
            </div>

            {lastReceipt && (
              <div className="mb-3 flex items-center gap-2 rounded-lg bg-emerald-950/50 px-3 py-2 text-xs text-emerald-300">
                <Receipt className="h-4 w-4 shrink-0" />
                Transaksi {lastReceipt} berhasil
              </div>
            )}

            {pendingCount > 0 && (
              <div className="mb-3 rounded-lg bg-amber-950/50 px-3 py-2 text-xs text-amber-300">
                {pendingCount} transaksi menunggu sinkronisasi
              </div>
            )}

            <div className="grid grid-cols-4 gap-2">
              <Button
                variant="outline"
                className="col-span-1 h-14 border-slate-600 bg-slate-800 text-white hover:bg-slate-700"
                disabled={items.length === 0}
                onClick={() => setHeldPanelOpen(true)}
              >
                <Clock className="h-5 w-5" />
              </Button>
              <Button
                className="col-span-3 h-14 bg-emerald-600 text-lg font-bold hover:bg-emerald-500 disabled:opacity-40"
                disabled={items.length === 0 || (isOnline && !shift)}
                onClick={handlePay}
              >
                BAYAR
              </Button>
            </div>
          </div>
        </aside>
      </div>

      {outletId && (
        <>
          <ShiftDialog
            open={shiftDialog !== null}
            mode={shiftDialog ?? "open"}
            outletId={outletId}
            shift={shift}
            onClose={() => setShiftDialog(null)}
            onSuccess={handleShiftSuccess}
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
            onSuccess={handlePaymentSuccess}
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