"use client";

import { useQuery } from "@tanstack/react-query";
import { X } from "lucide-react";
import { PosReceipt } from "@/components/pos/pos-receipt";
import { ReceiptDialogFooter } from "@/components/pos/receipt-dialog-footer";
import { getTransactionReceipt } from "@/lib/api/pos";

interface TransactionReceiptDialogProps {
  open: boolean;
  transactionUuid: string | null;
  transactionNumber?: string;
  onClose: () => void;
}

export function TransactionReceiptDialog({
  open,
  transactionUuid,
  transactionNumber,
  onClose,
}: TransactionReceiptDialogProps) {
  const { data: receipt, isLoading, isError } = useQuery({
    queryKey: ["pos", "receipt", transactionUuid],
    queryFn: () => getTransactionReceipt(transactionUuid!),
    enabled: open && !!transactionUuid,
    staleTime: 60 * 1000,
  });

  if (!open || !transactionUuid) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">Struk Transaksi</h2>
            <p className="text-xs text-muted-foreground">
              {transactionNumber ?? receipt?.transaction_number ?? transactionUuid}
            </p>
          </div>
          <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="max-h-[70vh] overflow-y-auto p-6">
          {isLoading ? (
            <div className="h-48 animate-pulse rounded-lg bg-slate-100" />
          ) : isError || !receipt ? (
            <p className="text-center text-sm text-red-600">Gagal memuat struk transaksi.</p>
          ) : (
            <div id="history-receipt-print">
              <PosReceipt transaction={receipt} pendingSync={false} />
            </div>
          )}
        </div>
        {receipt && (
          <ReceiptDialogFooter
            receiptElementId="history-receipt-print"
            onClose={onClose}
            closeLabel="Tutup"
          />
        )}
        {!receipt && !isLoading && (
          <div className="border-t border-border p-4">
            <button
              type="button"
              onClick={onClose}
              className="w-full rounded-lg border border-border px-4 py-2 text-sm hover:bg-slate-50"
            >
              Tutup
            </button>
          </div>
        )}
      </div>
    </div>
  );
}