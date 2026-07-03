"use client";

import { useEffect, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { CreditCard, QrCode, Wallet, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { getErrorMessage } from "@/lib/api/client";
import {
  getPaymentMethods,
  initiateInvoicePayment,
} from "@/lib/api/billing";
import { formatCurrency } from "@/lib/utils/format";
import type {
  BillingInvoice,
  BillingPaymentResult,
} from "@/types/settings";

interface InvoicePaymentDialogProps {
  open: boolean;
  invoice: BillingInvoice | null;
  onClose: () => void;
  onSuccess: () => void;
}

const methodIcons: Record<string, typeof CreditCard> = {
  va_bca: Wallet,
  va_bni: Wallet,
  va_bri: Wallet,
  qris: QrCode,
  gopay: Wallet,
  ovo: Wallet,
  dana: Wallet,
  credit_card: CreditCard,
  cod: Wallet,
};

export function InvoicePaymentDialog({
  open,
  invoice,
  onClose,
  onSuccess,
}: InvoicePaymentDialogProps) {
  const [selectedMethod, setSelectedMethod] = useState("");
  const [enableRecurring, setEnableRecurring] = useState(false);
  const [paymentResult, setPaymentResult] = useState<BillingPaymentResult | null>(
    null
  );

  const { data: methods = [] } = useQuery({
    queryKey: ["billing", "payment-methods"],
    queryFn: getPaymentMethods,
    enabled: open,
    staleTime: 5 * 60 * 1000,
  });

  useEffect(() => {
    if (!open) {
      setSelectedMethod("");
      setEnableRecurring(false);
      setPaymentResult(null);
      return;
    }

    if (methods.length > 0 && !selectedMethod) {
      setSelectedMethod(methods[0].code);
    }
  }, [open, methods, selectedMethod]);

  const payMutation = useMutation({
    mutationFn: () =>
      initiateInvoicePayment(invoice!.id, {
        payment_method: selectedMethod,
        enable_recurring: enableRecurring,
      }),
    onSuccess: (result) => {
      setPaymentResult(result);
      if (result.payment_status === "paid") {
        toast.success("Pembayaran berhasil!");
        onSuccess();
        onClose();
        return;
      }
      toast.success("Instruksi pembayaran siap");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!open || !invoice) return null;

  const instructions = paymentResult?.payment_instructions;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">Bayar Invoice</h2>
            <p className="text-sm text-muted-foreground">
              {invoice.invoice_number} · {formatCurrency(invoice.total_amount)}
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

        <div className="space-y-4 px-6 py-5">
          {!paymentResult ? (
            <>
              <p className="text-sm text-muted-foreground">
                Pilih metode pembayaran. Kartu kredit via Xendit mendukung
                langganan otomatis.
              </p>

              <div className="grid gap-2">
                {methods.map((method) => {
                  const Icon = methodIcons[method.code] ?? Wallet;
                  const active = selectedMethod === method.code;

                  return (
                    <button
                      key={method.code}
                      type="button"
                      onClick={() => setSelectedMethod(method.code)}
                      className={`flex items-center gap-3 rounded-lg border px-4 py-3 text-left transition ${
                        active
                          ? "border-primary bg-primary/5"
                          : "border-border hover:bg-slate-50"
                      }`}
                    >
                      <Icon className="h-5 w-5 text-primary" />
                      <div className="flex-1">
                        <p className="font-medium">{method.label}</p>
                        <p className="text-xs text-muted-foreground">
                          {method.gateway === "xendit"
                            ? "Xendit · Recurring"
                            : method.gateway === "cod"
                              ? "Konfirmasi manual"
                              : "Midtrans"}
                        </p>
                      </div>
                    </button>
                  );
                })}
              </div>

              {selectedMethod === "credit_card" && (
                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={enableRecurring}
                    onChange={(e) => setEnableRecurring(e.target.checked)}
                    className="h-4 w-4 rounded border-border"
                  />
                  Aktifkan perpanjangan otomatis (recurring)
                </label>
              )}

              <Button
                className="w-full"
                onClick={() => payMutation.mutate()}
                isLoading={payMutation.isPending}
                disabled={!selectedMethod}
              >
                Lanjutkan Pembayaran
              </Button>
            </>
          ) : (
            <div className="space-y-4">
              <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-800">
                Instruksi pembayaran untuk {paymentResult.invoice_number}
              </div>

              {instructions?.va_number && (
                <div className="rounded-lg border border-border p-4">
                  <p className="text-xs text-muted-foreground">Virtual Account</p>
                  <p className="text-lg font-bold tracking-wide">
                    {instructions.va_number}
                  </p>
                  {instructions.bank && (
                    <p className="text-sm text-muted-foreground">
                      Bank: {instructions.bank}
                    </p>
                  )}
                </div>
              )}

              {instructions?.qr_string && (
                <div className="rounded-lg border border-border p-4">
                  <p className="text-xs text-muted-foreground">QRIS</p>
                  <p className="break-all font-mono text-xs">
                    {instructions.qr_string}
                  </p>
                </div>
              )}

              {instructions?.biller_code && instructions?.bill_key && (
                <div className="rounded-lg border border-border p-4">
                  <p className="text-xs text-muted-foreground">OVO / E-Channel</p>
                  <p className="text-sm">
                    Kode: {instructions.biller_code} · Bill Key:{" "}
                    {instructions.bill_key}
                  </p>
                </div>
              )}

              {instructions?.message && (
                <p className="text-sm text-muted-foreground">
                  {instructions.message}
                </p>
              )}

              {paymentResult.payment_url && (
                <a
                  href={paymentResult.payment_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block"
                >
                  <Button className="w-full">Buka Halaman Pembayaran</Button>
                </a>
              )}

              {instructions?.mode === "sandbox_mock" && (
                <p className="text-xs text-amber-700">
                  Mode demo: API key belum dikonfigurasi. Data di atas simulasi
                  untuk testing.
                </p>
              )}

              <Button variant="outline" className="w-full" onClick={onClose}>
                Tutup
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}