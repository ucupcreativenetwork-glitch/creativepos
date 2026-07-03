import type {
  CreateTransactionPayload,
  PaymentMethod,
  PosCategory,
  PosProduct,
  PosTransaction,
  TransactionItem,
} from "@/types/pos";

export interface OfflineReceiptData {
  transaction_number: string;
  pendingSync: boolean;
  subtotal: number;
  discount_total: number;
  tax_total: number;
  service_charge: number;
  grand_total: number;
  completed_at: string;
  outlet?: { name: string; address?: string | null };
  cashier?: { name: string };
  items: TransactionItem[];
  payments: {
    amount: number;
    payment_method?: { name: string } | null;
  }[];
  wifi?: { ssid: string; password: string } | null;
}

export type OfflineReceiptTransaction = OfflineReceiptData &
  Pick<PosTransaction, "transaction_number" | "subtotal" | "grand_total">;

export interface CachedPosCatalog {
  products: PosProduct[];
  categories: PosCategory[];
  paymentMethods: PaymentMethod[];
  lastRefreshedAt: string;
  outletId?: number;
}

export interface OfflineSyncResult {
  synced: number;
  failed: number;
  syncedReceipts: PosTransaction[];
  failedEntries: { id: string; reason: string }[];
}

export interface EnqueueOfflineTransactionInput {
  payload: CreateTransactionPayload;
  idempotencyKey: string;
  receipt: OfflineReceiptData;
}