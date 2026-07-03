"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Clock, Play, Trash2, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { QueryErrorState } from "@/components/ui/query-error-state";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import {
  deleteHeldTransaction,
  getHeldTransactions,
  holdTransaction,
  resumeHeldTransaction,
  type HeldTransactionResume,
} from "@/lib/api/pos";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import type { CartItem } from "@/types/pos";

interface HeldTransactionsPanelProps {
  open: boolean;
  onClose: () => void;
  outletId?: number;
  items: CartItem[];
  onHoldSuccess: () => void;
  onResume: (data: HeldTransactionResume) => void;
}

export function HeldTransactionsPanel({
  open,
  onClose,
  outletId,
  items,
  onHoldSuccess,
  onResume,
}: HeldTransactionsPanelProps) {
  const queryClient = useQueryClient();
  const [referenceName, setReferenceName] = useState("");
  const [mode, setMode] = useState<"list" | "hold">("list");

  const {
    data: heldList = [],
    isLoading,
    isError,
    error,
    refetch,
  } = useQuery({
    queryKey: ["pos", "held", outletId],
    queryFn: () => getHeldTransactions({ outlet_id: outletId }),
    enabled: open && !!outletId,
    staleTime: 10_000,
  });

  const holdMutation = useMutation({
    mutationFn: holdTransaction,
    onSuccess: () => {
      toast.success("Transaksi ditahan");
      setReferenceName("");
      setMode("list");
      onHoldSuccess();
      queryClient.invalidateQueries({ queryKey: ["pos", "held"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const resumeMutation = useMutation({
    mutationFn: resumeHeldTransaction,
    onSuccess: (data) => {
      toast.success(`Transaksi "${data.reference_name}" dilanjutkan`);
      onResume(data);
      queryClient.invalidateQueries({ queryKey: ["pos", "held"] });
      onClose();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteHeldTransaction,
    onSuccess: () => {
      toast.success("Transaksi ditahan dihapus");
      queryClient.invalidateQueries({ queryKey: ["pos", "held"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  function handleHold() {
    if (!outletId) return;
    if (!referenceName.trim()) {
      toast.error("Nama referensi wajib diisi (contoh: Meja 3)");
      return;
    }
    if (items.length === 0) {
      toast.error("Keranjang kosong");
      return;
    }

    holdMutation.mutate({
      outlet_id: outletId,
      reference_name: referenceName.trim(),
      items: items.map((item) => ({
        product_id: item.product.id,
        quantity: item.quantity,
        unit_price: item.unitPrice,
        product_name: item.product.name,
        sku: item.product.sku,
        modifiers: item.modifiers.map((m) => ({
          modifier_id: m.modifier_id,
          name: m.name,
          price_adjustment: m.price_adjustment,
        })),
      })),
    });
  }

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/40">
      <div className="flex h-full w-full max-w-md flex-col bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">Transaksi Ditahan</h2>
            <p className="text-sm text-muted-foreground">
              {heldList.length} transaksi tersimpan
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

        <div className="flex border-b border-border px-4">
          <button
            type="button"
            onClick={() => setMode("list")}
            className={`px-4 py-2.5 text-sm font-medium ${
              mode === "list"
                ? "border-b-2 border-primary text-primary"
                : "text-muted-foreground"
            }`}
          >
            Daftar
          </button>
          <button
            type="button"
            onClick={() => setMode("hold")}
            className={`px-4 py-2.5 text-sm font-medium ${
              mode === "hold"
                ? "border-b-2 border-primary text-primary"
                : "text-muted-foreground"
            }`}
          >
            Tahan Baru
          </button>
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          {mode === "hold" ? (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>Nama Referensi</Label>
                <Input
                  value={referenceName}
                  onChange={(e) => setReferenceName(e.target.value)}
                  placeholder="Contoh: Meja 3 / Pak Budi"
                />
              </div>
              <div className="rounded-lg border border-border p-3 text-sm">
                <p className="font-medium">{items.length} item di keranjang</p>
                <p className="text-muted-foreground">
                  Total:{" "}
                  {formatCurrency(
                    items.reduce(
                      (sum, i) => sum + i.unitPrice * i.quantity,
                      0
                    )
                  )}
                </p>
              </div>
              <Button
                className="w-full"
                onClick={handleHold}
                isLoading={holdMutation.isPending}
                disabled={items.length === 0}
              >
                <Clock className="h-4 w-4" />
                Tahan Transaksi
              </Button>
            </div>
          ) : isError ? (
            <QueryErrorState
              message={getErrorMessage(error)}
              onRetry={() => void refetch()}
            />
          ) : isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-16 animate-pulse rounded-lg bg-slate-100" />
              ))}
            </div>
          ) : heldList.length === 0 ? (
            <p className="py-12 text-center text-sm text-muted-foreground">
              Belum ada transaksi ditahan
            </p>
          ) : (
            <div className="space-y-3">
              {heldList.map((held) => (
                <div
                  key={held.id}
                  className="rounded-lg border border-border p-3"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="font-medium">{held.reference_name}</p>
                      <p className="text-xs text-muted-foreground">
                        {held.item_count} item ·{" "}
                        {formatCurrency(held.subtotal)}
                      </p>
                      {held.held_at && (
                        <p className="mt-1 text-[10px] text-muted-foreground">
                          {formatDate(held.held_at, {
                            day: "numeric",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                        </p>
                      )}
                    </div>
                    <div className="flex gap-1">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => resumeMutation.mutate(held.id)}
                        isLoading={
                          resumeMutation.isPending &&
                          resumeMutation.variables === held.id
                        }
                      >
                        <Play className="h-3.5 w-3.5" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        className="text-red-600"
                        onClick={() => {
                          if (
                            !window.confirm(
                              `Hapus transaksi ditahan "${held.reference_name}"?`
                            )
                          ) {
                            return;
                          }
                          deleteMutation.mutate(held.id);
                        }}
                        isLoading={
                          deleteMutation.isPending &&
                          deleteMutation.variables === held.id
                        }
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}