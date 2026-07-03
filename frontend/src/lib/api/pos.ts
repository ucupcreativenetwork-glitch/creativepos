import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { PaginatedMeta } from "@/types/inventory";
import type {
  CreateTransactionPayload,
  PaymentMethod,
  PosCategory,
  PosProduct,
  PosTransaction,
  Shift,
} from "@/types/pos";

export async function getPosProducts(params?: {
  search?: string;
  category_id?: number;
}): Promise<PosProduct[]> {
  const { data } = await apiClient.get<ApiResponse<PosProduct[]>>(
    "/pos/catalog/products",
    { params }
  );
  return data.data;
}

export async function getPosCategories(): Promise<PosCategory[]> {
  const { data } = await apiClient.get<ApiResponse<PosCategory[]>>(
    "/pos/catalog/categories"
  );
  return data.data;
}

export async function getPaymentMethods(): Promise<PaymentMethod[]> {
  const { data } = await apiClient.get<ApiResponse<PaymentMethod[]>>(
    "/pos/catalog/payment-methods"
  );
  return data.data;
}

export async function getCurrentShift(outletId?: number): Promise<Shift | null> {
  const { data } = await apiClient.get<ApiResponse<Shift | null>>(
    "/pos/shifts/current",
    { params: outletId ? { outlet_id: outletId } : undefined }
  );
  return data.data ?? null;
}

export async function openShift(
  outletId: number,
  openingCash: number
): Promise<Shift> {
  const { data } = await apiClient.post<ApiResponse<Shift>>("/pos/shifts/open", {
    outlet_id: outletId,
    opening_cash: openingCash,
  });
  return data.data;
}

export async function closeShift(
  shiftId: number,
  closingCash: number,
  notes?: string
): Promise<Shift> {
  const { data } = await apiClient.post<ApiResponse<Shift>>(
    `/pos/shifts/${shiftId}/close`,
    { closing_cash: closingCash, notes }
  );
  return data.data;
}

export async function createTransaction(
  payload: CreateTransactionPayload,
  idempotencyKey: string
): Promise<PosTransaction> {
  const { data } = await apiClient.post<ApiResponse<PosTransaction>>(
    "/pos/transactions",
    payload,
    {
      headers: {
        "X-Idempotency-Key": idempotencyKey,
      },
    }
  );
  return data.data;
}

export async function getTransactions(params?: {
  page?: number;
  search?: string;
}): Promise<{ data: PosTransaction[]; meta: PaginatedMeta }> {
  const { data } = await apiClient.get<
    ApiResponse<PosTransaction[]> & { meta?: PaginatedMeta }
  >("/pos/transactions", { params });

  return {
    data: data.data,
    meta: data.meta ?? {
      current_page: 1,
      per_page: data.data.length,
      total: data.data.length,
      last_page: 1,
    },
  };
}

export async function voidTransaction(
  uuid: string,
  reason?: string
): Promise<PosTransaction> {
  const { data } = await apiClient.post<ApiResponse<PosTransaction>>(
    `/pos/transactions/${uuid}/void`,
    { reason }
  );
  return data.data;
}

export interface HeldTransactionSummary {
  id: number;
  outlet_id: number;
  reference_name: string;
  subtotal: number;
  held_at?: string;
  item_count: number;
  items?: {
    product_id: number;
    product_name?: string;
    quantity: number;
    unit_price: number;
  }[];
}

export interface HeldTransactionResume {
  id: number;
  reference_name: string;
  outlet_id: number;
  subtotal: number;
  items: {
    product_id: number;
    product_name?: string;
    sku?: string;
    quantity: number;
    unit_price: number;
    modifiers: {
      modifier_id: number;
      name: string;
      price_adjustment: number;
    }[];
    product?: PosProduct | null;
  }[];
}

export async function getHeldTransactions(params?: {
  outlet_id?: number;
}): Promise<HeldTransactionSummary[]> {
  const { data } = await apiClient.get<ApiResponse<HeldTransactionSummary[]>>(
    "/pos/held",
    { params }
  );
  return data.data;
}

export async function holdTransaction(payload: {
  outlet_id: number;
  reference_name: string;
  items: {
    product_id: number;
    quantity: number;
    unit_price: number;
    product_name?: string;
    sku?: string;
    modifiers?: {
      modifier_id: number;
      name: string;
      price_adjustment: number;
    }[];
  }[];
}): Promise<HeldTransactionSummary> {
  const { data } = await apiClient.post<ApiResponse<HeldTransactionSummary>>(
    "/pos/held",
    payload
  );
  return data.data;
}

export async function resumeHeldTransaction(
  id: number
): Promise<HeldTransactionResume> {
  const { data } = await apiClient.post<ApiResponse<HeldTransactionResume>>(
    `/pos/held/${id}/resume`
  );
  return data.data;
}

export async function deleteHeldTransaction(id: number): Promise<void> {
  await apiClient.delete(`/pos/held/${id}`);
}

export async function getTransactionReceipt(
  uuid: string
): Promise<PosTransaction> {
  const { data } = await apiClient.get<ApiResponse<PosTransaction>>(
    `/pos/transactions/${uuid}/receipt`
  );
  return data.data;
}