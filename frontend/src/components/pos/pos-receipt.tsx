"use client";

import { formatCurrency } from "@/lib/utils/format";
import type { PosTransaction, SelectedModifier, TransactionItem } from "@/types/pos";

interface PosReceiptProps {
  pendingSync?: boolean;
  transaction: Pick<
    PosTransaction,
    | "transaction_number"
    | "subtotal"
    | "discount_total"
    | "tax_total"
    | "service_charge"
    | "grand_total"
    | "completed_at"
  > & {
    outlet?: { name: string; address?: string | null };
    cashier?: { name: string };
    items?: TransactionItem[];
    payments?: {
      amount: number;
      payment_method?: { name: string } | null;
    }[];
    wifi?: { ssid: string; password: string } | null;
  };
}

function ModifierLines({ modifiers }: { modifiers?: SelectedModifier[] }) {
  if (!modifiers?.length) return null;

  return (
    <ul className="mt-0.5 space-y-0.5 pl-1">
      {modifiers.map((modifier) => (
        <li key={modifier.modifier_id} className="text-[11px] text-muted-foreground">
          + {modifier.name}
        </li>
      ))}
    </ul>
  );
}

export function PosReceipt({ transaction, pendingSync = false }: PosReceiptProps) {
  const showPending = pendingSync || (transaction as { pendingSync?: boolean }).pendingSync;

  return (
    <div className="relative space-y-4 font-mono text-xs">
      {showPending && (
        <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
          <p className="rotate-[-18deg] rounded border-2 border-amber-500 px-4 py-2 text-lg font-bold uppercase tracking-widest text-amber-500/70">
            Pending Sync
          </p>
        </div>
      )}

      <div className="text-center">
        <p className="text-sm font-semibold">{transaction.outlet?.name ?? "CreativePOS"}</p>
        {transaction.outlet?.address && (
          <p className="text-[10px] text-muted-foreground">{transaction.outlet.address}</p>
        )}
        <p className="mt-2 font-medium">{transaction.transaction_number}</p>
        {transaction.completed_at && (
          <p className="text-[10px] text-muted-foreground">
            {new Date(transaction.completed_at).toLocaleString("id-ID")}
          </p>
        )}
        {transaction.cashier?.name && (
          <p className="text-[10px] text-muted-foreground">
            Kasir: {transaction.cashier.name}
          </p>
        )}
      </div>

      <div className="border-t border-dashed border-border pt-3">
        {transaction.items?.map((item, index) => (
          <div key={`${item.product_name}-${index}`} className="mb-3">
            <div className="flex justify-between gap-2">
              <div className="min-w-0 flex-1">
                <p className="font-medium">{item.product_name}</p>
                <ModifierLines modifiers={item.modifiers} />
              </div>
              <p className="shrink-0">{formatCurrency(item.subtotal)}</p>
            </div>
            <p className="text-[10px] text-muted-foreground">
              {item.quantity} x {formatCurrency(item.unit_price)}
            </p>
          </div>
        ))}
      </div>

      <div className="space-y-1 border-t border-dashed border-border pt-3">
        <div className="flex justify-between">
          <span>Subtotal</span>
          <span>{formatCurrency(transaction.subtotal)}</span>
        </div>
        {transaction.discount_total > 0 && (
          <div className="flex justify-between">
            <span>Diskon</span>
            <span>-{formatCurrency(transaction.discount_total)}</span>
          </div>
        )}
        {transaction.tax_total > 0 && (
          <div className="flex justify-between">
            <span>Pajak</span>
            <span>{formatCurrency(transaction.tax_total)}</span>
          </div>
        )}
        {transaction.service_charge > 0 && (
          <div className="flex justify-between">
            <span>Service</span>
            <span>{formatCurrency(transaction.service_charge)}</span>
          </div>
        )}
        <div className="flex justify-between text-sm font-semibold">
          <span>Total</span>
          <span>{formatCurrency(transaction.grand_total)}</span>
        </div>
      </div>

      {transaction.payments && transaction.payments.length > 0 && (
        <div className="border-t border-dashed border-border pt-3">
          {transaction.payments.map((payment, index) => (
            <div key={index} className="flex justify-between">
              <span>{payment.payment_method?.name ?? "Pembayaran"}</span>
              <span>{formatCurrency(payment.amount)}</span>
            </div>
          ))}
        </div>
      )}

      {transaction.wifi && (
        <div className="border-t border-dashed border-border pt-3 text-center text-[10px]">
          <p className="font-semibold">WiFi Gratis</p>
          <p>SSID: {transaction.wifi.ssid}</p>
          <p>Password: {transaction.wifi.password}</p>
        </div>
      )}

      <p className="text-center text-[10px] text-muted-foreground">
        Terima kasih atas kunjungan Anda
      </p>
    </div>
  );
}