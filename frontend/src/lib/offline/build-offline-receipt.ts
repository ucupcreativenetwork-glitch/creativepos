import type { OfflineReceiptData } from "@/types/offline";
import type { CartItem, PaymentMethod } from "@/types/pos";

interface BuildOfflineReceiptParams {
  items: CartItem[];
  grandTotal: number;
  paymentMethod?: PaymentMethod | null;
  outletName?: string;
  cashierName?: string;
  wifi?: { ssid: string; password: string } | null;
}

export function buildOfflineTransactionNumber(): string {
  const stamp = Date.now().toString(36).toUpperCase();
  return `OFFLINE-${stamp}`;
}

export function buildOfflineReceipt(
  params: BuildOfflineReceiptParams
): OfflineReceiptData {
  const txNumber = buildOfflineTransactionNumber();
  const completedAt = new Date().toISOString();

  const receiptItems = params.items.map((item, index) => ({
    id: index + 1,
    product_id: item.product.id,
    product_name: item.product.name,
    sku: item.product.sku,
    quantity: item.quantity,
    unit_price: item.unitPrice,
    modifiers: item.modifiers,
    modifier_price_adjustment: item.modifiers.reduce(
      (sum, m) => sum + m.price_adjustment,
      0
    ),
    subtotal: item.unitPrice * item.quantity,
  }));

  const subtotal = receiptItems.reduce((sum, item) => sum + item.subtotal, 0);

  return {
    transaction_number: txNumber,
    pendingSync: true,
    subtotal,
    discount_total: 0,
    tax_total: 0,
    service_charge: 0,
    grand_total: params.grandTotal,
    completed_at: completedAt,
    outlet: params.outletName ? { name: params.outletName } : undefined,
    cashier: params.cashierName ? { name: params.cashierName } : undefined,
    items: receiptItems,
    payments: [
      {
        amount: params.grandTotal,
        payment_method: params.paymentMethod
          ? { name: params.paymentMethod.name }
          : { name: "Offline" },
      },
    ],
    wifi: params.wifi ?? null,
  };
}