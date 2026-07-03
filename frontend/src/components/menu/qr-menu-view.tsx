"use client";

import { useMemo, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Bell, Minus, Plus, Receipt, ShoppingBag } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  callWaiter,
  requestBill,
  submitPublicOrder,
} from "@/lib/api/public-menu";
import { formatCurrency } from "@/lib/utils/format";
import type { CartItem, DigitalMenu } from "@/types/order";

interface QrMenuViewProps {
  menu: DigitalMenu;
  tenantSlug: string;
  outletSlug: string;
  tableToken?: string;
}

export function QrMenuView({
  menu,
  tenantSlug,
  outletSlug,
  tableToken,
}: QrMenuViewProps) {
  const [categoryId, setCategoryId] = useState<number | undefined>();
  const [cart, setCart] = useState<CartItem[]>([]);
  const [notes, setNotes] = useState("");
  const [orderUuid, setOrderUuid] = useState<string | null>(null);
  const [showCart, setShowCart] = useState(false);

  const theme = menu.settings.theme_color;

  const products = useMemo(() => {
    if (!categoryId) return menu.products;
    return menu.products.filter((p) => p.category_id === categoryId);
  }, [menu.products, categoryId]);

  const total = cart.reduce(
    (sum, item) => sum + item.product.base_price * item.quantity,
    0
  );

  const addToCart = (product: CartItem["product"]) => {
    setCart((prev) => {
      const existing = prev.find((i) => i.product.id === product.id);
      if (existing) {
        return prev.map((i) =>
          i.product.id === product.id
            ? { ...i, quantity: i.quantity + 1 }
            : i
        );
      }
      return [...prev, { product, quantity: 1 }];
    });
  };

  const orderMutation = useMutation({
    mutationFn: () =>
      submitPublicOrder({
        tenant_slug: tenantSlug,
        outlet_slug: outletSlug,
        table_token: tableToken,
        notes: notes || undefined,
        items: cart.map((i) => ({
          product_id: i.product.id,
          quantity: i.quantity,
        })),
      }),
    onSuccess: (order) => {
      setOrderUuid(order.uuid);
      setCart([]);
      setShowCart(false);
      toast.success("Pesanan berhasil dikirim!");
    },
    onError: () => toast.error("Gagal mengirim pesanan"),
  });

  const waiterMutation = useMutation({
    mutationFn: () =>
      callWaiter({
        tenant_slug: tenantSlug,
        outlet_slug: outletSlug,
        table_token: tableToken!,
      }),
    onSuccess: () => toast.success("Pelayan dipanggil"),
    onError: () => toast.error("Gagal memanggil pelayan"),
  });

  const billMutation = useMutation({
    mutationFn: () =>
      requestBill({
        tenant_slug: tenantSlug,
        outlet_slug: outletSlug,
        table_token: tableToken!,
      }),
    onSuccess: () => toast.success("Permintaan tagihan dikirim"),
    onError: () => toast.error("Gagal meminta tagihan"),
  });

  if (orderUuid) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-slate-50 p-6 text-center">
        <div
          className="mb-4 flex h-16 w-16 items-center justify-center rounded-full text-white"
          style={{ backgroundColor: theme }}
        >
          <ShoppingBag className="h-8 w-8" />
        </div>
        <h1 className="text-xl font-bold">Pesanan Terkirim!</h1>
        <p className="mt-2 text-muted-foreground">
          Pesanan Anda sedang diproses dapur.
        </p>
        <a
          href={`/menu/track/${orderUuid}`}
          className="mt-6 text-sm font-medium underline"
          style={{ color: theme }}
        >
          Lacak status pesanan
        </a>
        <button
          type="button"
          className="mt-4 text-sm text-muted-foreground underline"
          onClick={() => setOrderUuid(null)}
        >
          Pesan lagi
        </button>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50">
      <header
        className="px-6 py-8 text-white"
        style={{ backgroundColor: theme }}
      >
        <p className="text-sm opacity-80">{menu.tenant.name}</p>
        <h1 className="text-2xl font-bold">{menu.outlet.name}</h1>
        {menu.table && (
          <p className="mt-1 text-sm opacity-90">
            Meja {menu.table.table_number}
            {menu.table.name ? ` — ${menu.table.name}` : ""}
          </p>
        )}
        <p className="mt-3 text-sm opacity-90">
          {menu.settings.welcome_message}
        </p>
      </header>

      {tableToken && (
        <div className="flex gap-2 border-b border-border bg-white px-4 py-2">
          <Button
            variant="outline"
            size="sm"
            className="flex-1"
            onClick={() => waiterMutation.mutate()}
            isLoading={waiterMutation.isPending}
          >
            <Bell className="h-4 w-4" /> Panggil Pelayan
          </Button>
          <Button
            variant="outline"
            size="sm"
            className="flex-1"
            onClick={() => billMutation.mutate()}
            isLoading={billMutation.isPending}
          >
            <Receipt className="h-4 w-4" /> Minta Tagihan
          </Button>
        </div>
      )}

      <div className="flex gap-2 overflow-x-auto px-4 py-3">
        <button
          type="button"
          onClick={() => setCategoryId(undefined)}
          className={`shrink-0 rounded-full px-3 py-1 text-xs font-medium ${
            !categoryId ? "text-white" : "bg-white text-muted-foreground"
          }`}
          style={!categoryId ? { backgroundColor: theme } : undefined}
        >
          Semua
        </button>
        {menu.categories.map((cat) => (
          <button
            key={cat.id}
            type="button"
            onClick={() => setCategoryId(cat.id)}
            className={`shrink-0 rounded-full px-3 py-1 text-xs font-medium ${
              categoryId === cat.id
                ? "text-white"
                : "bg-white text-muted-foreground"
            }`}
            style={
              categoryId === cat.id ? { backgroundColor: theme } : undefined
            }
          >
            {cat.name}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-3 p-4 pb-24">
        {products.map((product) => (
          <button
            key={product.id}
            type="button"
            onClick={() => addToCart(product)}
            disabled={!menu.settings.allow_guest_order}
            className="rounded-xl bg-white p-3 text-left shadow-sm transition-shadow hover:shadow-md disabled:opacity-50"
          >
            <p className="line-clamp-2 text-sm font-medium">{product.name}</p>
            {menu.settings.show_prices && (
              <p className="mt-2 text-sm font-semibold" style={{ color: theme }}>
                {formatCurrency(product.base_price)}
              </p>
            )}
          </button>
        ))}
      </div>

      {cart.length > 0 && (
        <div className="fixed bottom-0 left-0 right-0 border-t border-border bg-white p-4 shadow-lg">
          {showCart ? (
            <div className="mb-3 max-h-48 space-y-2 overflow-y-auto">
              {cart.map((item) => (
                <div
                  key={item.product.id}
                  className="flex items-center justify-between text-sm"
                >
                  <span className="flex-1 truncate">{item.product.name}</span>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() =>
                        setCart((prev) =>
                          prev
                            .map((i) =>
                              i.product.id === item.product.id
                                ? { ...i, quantity: i.quantity - 1 }
                                : i
                            )
                            .filter((i) => i.quantity > 0)
                        )
                      }
                    >
                      <Minus className="h-4 w-4" />
                    </button>
                    <span>{item.quantity}</span>
                    <button
                      type="button"
                      onClick={() => addToCart(item.product)}
                    >
                      <Plus className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              ))}
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Catatan pesanan (opsional)"
                className="mt-2 w-full rounded-lg border border-border p-2 text-sm"
                rows={2}
              />
            </div>
          ) : null}

          <div className="flex items-center gap-3">
            <button
              type="button"
              className="text-sm text-muted-foreground underline"
              onClick={() => setShowCart(!showCart)}
            >
              {cart.length} item · {formatCurrency(total)}
            </button>
            <Button
              className="ml-auto flex-1"
              style={{ backgroundColor: theme }}
              onClick={() => orderMutation.mutate()}
              isLoading={orderMutation.isPending}
            >
              Pesan Sekarang
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}