import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type {
  BillingInvoice,
  BillingPaymentMethod,
  BillingPaymentResult,
  SubscriptionInfo,
} from "@/types/settings";

export async function getSubscription(): Promise<SubscriptionInfo | null> {
  const { data } = await apiClient.get<ApiResponse<SubscriptionInfo | null>>(
    "/billing/subscription"
  );
  return data.data ?? null;
}

export async function getInvoices(params?: {
  page?: number;
  per_page?: number;
}): Promise<BillingInvoice[]> {
  const { data } = await apiClient.get<ApiResponse<BillingInvoice[]>>(
    "/billing/invoices",
    { params }
  );
  return data.data ?? [];
}

export async function getPaymentMethods(): Promise<BillingPaymentMethod[]> {
  const { data } = await apiClient.get<ApiResponse<BillingPaymentMethod[]>>(
    "/billing/payment-methods"
  );
  return data.data ?? [];
}

export async function initiateInvoicePayment(
  invoiceId: number,
  payload: { payment_method: string; enable_recurring?: boolean }
): Promise<BillingPaymentResult> {
  const { data } = await apiClient.post<ApiResponse<BillingPaymentResult>>(
    `/billing/invoices/${invoiceId}/pay`,
    payload
  );
  return data.data;
}

export async function getInvoicePaymentStatus(
  invoiceId: number
): Promise<BillingPaymentResult> {
  const { data } = await apiClient.get<ApiResponse<BillingPaymentResult>>(
    `/billing/invoices/${invoiceId}/payment-status`
  );
  return data.data;
}

export async function setupRecurringSubscription(): Promise<{
  subscription_id: number;
  auto_renew: boolean;
  payment_url?: string | null;
  provider: string;
}> {
  const { data } = await apiClient.post<
    ApiResponse<{
      subscription_id: number;
      auto_renew: boolean;
      payment_url?: string | null;
      provider: string;
    }>
  >("/billing/subscription/recurring");
  return data.data;
}