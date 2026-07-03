"use client";

import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Search, User, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import { findMemberByCode, getMemberPoints, getMembers } from "@/lib/api/members";
import { createTransaction } from "@/lib/api/pos";
import { buildOfflineReceipt } from "@/lib/offline/build-offline-receipt";
import { isNetworkError } from "@/lib/offline/network";
import { formatCurrency } from "@/lib/utils/format";
import { PosReceipt } from "@/components/pos/pos-receipt";
import { ReceiptDialogFooter } from "@/components/pos/receipt-dialog-footer";
import type { EnqueueOfflineTransactionInput } from "@/types/offline";
import type { Member } from "@/types/loyalty";
import type { CartItem, PaymentMethod, PosTransaction, Shift } from "@/types/pos";
import type { OfflineReceiptData } from "@/types/offline";

type ReceiptView = PosTransaction | OfflineReceiptData;

interface PaymentDialogProps {
  open: boolean;
  items: CartItem[];
  subtotal: number;
  taxRate: number;
  serviceRate: number;
  outletId: number;
  outletName?: string;
  shift?: Shift | null;
  paymentMethods: PaymentMethod[];
  isOnline: boolean;
  onEnqueueOffline: (input: EnqueueOfflineTransactionInput) => Promise<unknown>;
  onClose: () => void;
  onSuccess: (transactionNumber: string, receipt?: ReceiptView) => void;
}

export function PaymentDialog({
  open,
  items,
  subtotal,
  taxRate,
  serviceRate,
  outletId,
  outletName,
  shift,
  paymentMethods,
  isOnline,
  onEnqueueOffline,
  onClose,
  onSuccess,
}: PaymentDialogProps) {
  const [methodId, setMethodId] = useState<number | "">("");
  const [reference, setReference] = useState("");
  const [cashReceived, setCashReceived] = useState("");
  const [idempotencyKey, setIdempotencyKey] = useState("");
  const [completedReceipt, setCompletedReceipt] = useState<ReceiptView | null>(null);
  const [isPendingSync, setIsPendingSync] = useState(false);

  const [memberSearch, setMemberSearch] = useState("");
  const [selectedMember, setSelectedMember] = useState<Member | null>(null);
  const [pointsRedeem, setPointsRedeem] = useState("");
  const [memberCodeInput, setMemberCodeInput] = useState("");

  useEffect(() => {
    if (!open) return;

    setCompletedReceipt(null);
    setIsPendingSync(false);
    setIdempotencyKey(crypto.randomUUID());
    setSelectedMember(null);
    setMemberSearch("");
    setMemberCodeInput("");
    setPointsRedeem("");

    if (paymentMethods.length > 0) {
      setMethodId(paymentMethods[0].id);
      setReference("");
      setCashReceived("");
    }
  }, [open, paymentMethods]);

  const { data: memberResults } = useQuery({
    queryKey: ["members", "search", memberSearch],
    queryFn: () => getMembers({ search: memberSearch, per_page: 5 }),
    enabled: open && memberSearch.trim().length >= 2 && !selectedMember,
    staleTime: 10 * 1000,
  });

  const { data: memberPoints } = useQuery({
    queryKey: ["members", selectedMember?.uuid, "points"],
    queryFn: () => getMemberPoints(selectedMember!.uuid),
    enabled: open && !!selectedMember,
    staleTime: 15 * 1000,
  });

  const pointConfig = memberPoints?.config;
  const pointBalance = memberPoints?.balance ?? selectedMember?.points?.balance ?? 0;
  const minRedeem = pointConfig?.min_redeem_points ?? 100;
  const redeemPointsNum = Number(pointsRedeem) || 0;

  const pointDiscount = useMemo(() => {
    if (!pointConfig || redeemPointsNum < minRedeem || redeemPointsNum > pointBalance) {
      return 0;
    }
    return (
      Math.round(
        ((redeemPointsNum / pointConfig.redeem_points) * pointConfig.redeem_value) * 100
      ) / 100
    );
  }, [pointConfig, redeemPointsNum, minRedeem, pointBalance]);

  const taxableBase = Math.max(0, subtotal - pointDiscount);
  const taxAmount = Math.round(taxableBase * taxRate) / 100;
  const serviceAmount = Math.round(taxableBase * serviceRate) / 100;
  const finalTotal = taxableBase + taxAmount + serviceAmount;

  useEffect(() => {
    if (!selectedMember || !pointConfig) {
      setPointsRedeem("");
      return;
    }
    if (pointBalance >= minRedeem) {
      setPointsRedeem(String(Math.min(minRedeem, pointBalance)));
    }
  }, [selectedMember?.uuid, pointBalance, minRedeem, pointConfig]);

  const selectedMethod = paymentMethods.find((m) => m.id === Number(methodId));
  const isCash = selectedMethod?.type === "cash" || selectedMethod?.code === "cash";
  const cashReceivedNum = parseFloat(cashReceived.replace(/[^\d.]/g, "")) || 0;
  const change = isCash ? Math.max(0, cashReceivedNum - finalTotal) : 0;
  const cashInsufficient = isCash && cashReceivedNum > 0 && cashReceivedNum < finalTotal;

  const canRedeemPoints =
    !!selectedMember &&
    redeemPointsNum >= minRedeem &&
    redeemPointsNum <= pointBalance &&
    pointDiscount > 0;

  const buildPayload = () => ({
    outlet_id: outletId,
    shift_id: shift?.id,
    member_id: selectedMember?.id,
    order_type: "quick_sale" as const,
    points_redeem: canRedeemPoints ? redeemPointsNum : undefined,
    items: items.map((i) => ({
      product_id: i.product.id,
      quantity: i.quantity,
      modifiers:
        i.modifiers.length > 0
          ? i.modifiers.map((m) => m.modifier_id)
          : undefined,
    })),
    payments: [
      {
        payment_method_id: Number(methodId),
        amount: finalTotal,
        reference_number: reference || undefined,
      },
    ],
  });

  const lookupMemberByCode = async () => {
    const code = memberCodeInput.trim();
    if (!code) return;

    try {
      const member = await findMemberByCode(code);
      setSelectedMember(member);
      setMemberSearch("");
      setMemberCodeInput("");
    } catch (error) {
      toast.error(getErrorMessage(error));
    }
  };

  const processOffline = async () => {
    if (!idempotencyKey) {
      throw new Error("Sesi checkout belum siap.");
    }

    const paymentMethod = paymentMethods.find((m) => m.id === Number(methodId));
    const receipt = buildOfflineReceipt({
      items,
      grandTotal: finalTotal,
      paymentMethod,
      outletName,
    });

    await onEnqueueOffline({
      payload: buildPayload(),
      idempotencyKey,
      receipt,
    });

    toast.info("Transaksi disimpan offline. Akan disinkronkan saat online.");
    setCompletedReceipt(receipt);
    setIsPendingSync(true);
    onSuccess(receipt.transaction_number, receipt);
  };

  const stockIssues = items.filter(
    (item) =>
      item.product.track_stock && item.product.total_stock < item.quantity
  );

  const mutation = useMutation({
    mutationFn: async () => {
      if (!idempotencyKey) {
        throw new Error("Sesi checkout belum siap. Tutup dan buka ulang pembayaran.");
      }

      if (stockIssues.length > 0) {
        throw new Error(
          `Stok tidak mencukupi: ${stockIssues.map((i) => i.product.name).join(", ")}`
        );
      }

      if (!isOnline) {
        await processOffline();
        return null;
      }

      try {
        return await createTransaction(buildPayload(), idempotencyKey);
      } catch (error) {
        if (isNetworkError(error)) {
          await processOffline();
          return null;
        }
        throw error;
      }
    },
    onSuccess: (tx) => {
      if (!tx) return;
      toast.success("Transaksi berhasil!");
      setCompletedReceipt(tx);
      setIsPendingSync(false);
      onSuccess(tx.transaction_number, tx);
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!open) return null;

  if (completedReceipt) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
          <div className="flex items-center justify-between border-b border-border px-6 py-4">
            <h2 className="text-lg font-semibold">Struk</h2>
            <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
              <X className="h-5 w-5" />
            </button>
          </div>
          <div className="max-h-[70vh] overflow-y-auto p-6">
            <div id="payment-receipt-print">
              <PosReceipt transaction={completedReceipt} pendingSync={isPendingSync} />
            </div>
          </div>
          <ReceiptDialogFooter
            receiptElementId="payment-receipt-print"
            onClose={onClose}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="max-h-[90vh] w-full max-w-md overflow-y-auto rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold">Pembayaran</h2>
          <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 p-6">
          {!isOnline && (
            <div className="rounded-lg bg-amber-50 px-3 py-2 text-xs text-amber-800">
              Mode offline — transaksi akan masuk antrian dan disinkronkan otomatis.
            </div>
          )}

          <div className="space-y-1 rounded-lg bg-primary/5 p-4">
            <div className="flex justify-between text-sm">
              <span className="text-muted-foreground">Subtotal</span>
              <span>{formatCurrency(subtotal)}</span>
            </div>
            {pointDiscount > 0 && (
              <div className="flex justify-between text-sm text-violet-700">
                <span>Diskon Poin</span>
                <span>-{formatCurrency(pointDiscount)}</span>
              </div>
            )}
            {taxAmount > 0 && (
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Pajak ({taxRate}%)</span>
                <span>{formatCurrency(taxAmount)}</span>
              </div>
            )}
            {serviceAmount > 0 && (
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Service ({serviceRate}%)</span>
                <span>{formatCurrency(serviceAmount)}</span>
              </div>
            )}
            <div className="flex justify-between border-t border-primary/10 pt-2">
              <span className="font-semibold">Total Bayar</span>
              <span className="text-2xl font-bold text-primary">
                {formatCurrency(finalTotal)}
              </span>
            </div>
          </div>

          <div className="space-y-2">
            <Label>Member (opsional)</Label>
            {selectedMember ? (
              <div className="flex items-center justify-between rounded-lg border border-violet-200 bg-violet-50 px-3 py-2">
                <div className="flex items-center gap-2">
                  <User className="h-4 w-4 text-violet-600" />
                  <div>
                    <p className="text-sm font-medium">{selectedMember.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {selectedMember.member_code} · {pointBalance} poin
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedMember(null)}
                  className="text-xs text-muted-foreground hover:text-red-600"
                >
                  Hapus
                </button>
              </div>
            ) : (
              <div className="space-y-2">
                <div className="flex gap-2">
                  <Input
                    value={memberCodeInput}
                    onChange={(e) => setMemberCodeInput(e.target.value)}
                    placeholder="Scan / ketik kode member"
                    onKeyDown={(e) => e.key === "Enter" && void lookupMemberByCode()}
                  />
                  <Button type="button" variant="outline" onClick={() => void lookupMemberByCode()}>
                    Cari
                  </Button>
                </div>
                <div className="relative">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                  <Input
                    value={memberSearch}
                    onChange={(e) => setMemberSearch(e.target.value)}
                    placeholder="Cari nama atau telepon..."
                    className="pl-9"
                  />
                </div>
                {(memberResults?.data ?? []).length > 0 && memberSearch.length >= 2 && (
                  <div className="max-h-32 overflow-y-auto rounded-lg border border-border">
                    {memberResults?.data.map((m) => (
                      <button
                        key={m.uuid}
                        type="button"
                        onClick={() => {
                          setSelectedMember(m);
                          setMemberSearch("");
                        }}
                        className="flex w-full items-center justify-between px-3 py-2 text-left text-sm hover:bg-slate-50"
                      >
                        <span>{m.name}</span>
                        <span className="text-xs text-muted-foreground">{m.member_code}</span>
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          {selectedMember && pointConfig && pointBalance >= minRedeem && (
            <div className="space-y-2">
              <Label>Redeem Poin</Label>
              <div className="flex gap-2">
                <Input
                  type="number"
                  min={minRedeem}
                  max={pointBalance}
                  value={pointsRedeem}
                  onChange={(e) => setPointsRedeem(e.target.value)}
                  placeholder={`Min. ${minRedeem} poin`}
                />
              </div>
              {canRedeemPoints && (
                <p className="text-xs text-violet-700">
                  Diskon {formatCurrency(pointDiscount)} ({redeemPointsNum} poin)
                </p>
              )}
              {redeemPointsNum > 0 && redeemPointsNum < minRedeem && (
                <p className="text-xs text-muted-foreground">
                  Minimal redeem {minRedeem} poin
                </p>
              )}
            </div>
          )}

          <div className="space-y-2">
            <Label>Metode Pembayaran</Label>
            <select
              value={methodId}
              onChange={(e) => setMethodId(Number(e.target.value))}
              className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
            >
              {paymentMethods.map((m) => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
          </div>

          {isCash && (
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label>Uang Diterima</Label>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => setCashReceived(String(finalTotal))}
                >
                  Uang Pas
                </Button>
              </div>
              <Input
                type="number"
                min={0}
                step={1000}
                value={cashReceived}
                onChange={(e) => setCashReceived(e.target.value)}
                placeholder="Masukkan jumlah uang"
              />
              {cashReceivedNum > 0 && (
                <div
                  className={`rounded-lg px-3 py-2 text-sm ${
                    cashInsufficient
                      ? "bg-red-50 text-red-700"
                      : "bg-emerald-50 text-emerald-700"
                  }`}
                >
                  {cashInsufficient ? (
                    <span>
                      Kurang {formatCurrency(finalTotal - cashReceivedNum)}
                    </span>
                  ) : (
                    <span>Kembalian: {formatCurrency(change)}</span>
                  )}
                </div>
              )}
            </div>
          )}

          {!isCash && (
            <div className="space-y-2">
              <Label>No. Referensi</Label>
              <Input
                value={reference}
                onChange={(e) => setReference(e.target.value)}
                placeholder="Opsional (QRIS, transfer, dll.)"
              />
            </div>
          )}

          <div className="flex justify-end gap-3">
            <Button variant="outline" onClick={onClose}>Batal</Button>
            <Button
              onClick={() => mutation.mutate()}
              isLoading={mutation.isPending}
              disabled={
                !methodId ||
                items.length === 0 ||
                !idempotencyKey ||
                stockIssues.length > 0 ||
                (isCash && cashReceivedNum < finalTotal)
              }
            >
              {isOnline ? "Proses Pembayaran" : "Simpan Offline"}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}