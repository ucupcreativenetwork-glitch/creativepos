"use client";

import { X } from "lucide-react";
import { PosReceipt } from "@/components/pos/pos-receipt";
import { ReceiptDialogFooter } from "@/components/pos/receipt-dialog-footer";
import type { PosTransaction } from "@/types/pos";

interface SyncedReceiptDialogProps {
  open: boolean;
  transaction: PosTransaction | null;
  onClose: () => void;
}

export function SyncedReceiptDialog({
  open,
  transaction,
  onClose,
}: SyncedReceiptDialogProps) {
  if (!open || !transaction) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">Struk Tersinkronkan</h2>
            <p className="text-xs text-muted-foreground">
              {transaction.transaction_number}
            </p>
          </div>
          <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="max-h-[70vh] overflow-y-auto p-6">
          <div id="synced-receipt-print">
            <PosReceipt transaction={transaction} pendingSync={false} />
          </div>
        </div>
        <ReceiptDialogFooter
          receiptElementId="synced-receipt-print"
          onClose={onClose}
          closeLabel="Tutup"
        />
      </div>
    </div>
  );
}