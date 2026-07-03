import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { PaginatedMeta } from "@/types/loyalty";
import type { Order } from "@/types/order";

export async function getKitchenQueue(outletId?: number): Promise<Order[]> {
  const { data } = await apiClient.get<ApiResponse<Order[]>>("/kitchen/queue", {
    params: outletId ? { outlet_id: outletId } : undefined,
  });
  return data.data;
}

export async function bumpOrder(uuid: string): Promise<Order> {
  const { data } = await apiClient.patch<ApiResponse<Order>>(
    `/kitchen/orders/${uuid}/bump`
  );
  return data.data;
}

export async function getOrders(params?: {
  outlet_id?: number;
  status?: string;
  source?: string;
  page?: number;
}): Promise<{ data: Order[]; meta: PaginatedMeta }> {
  const { data } = await apiClient.get<ApiResponse<Order[]> & { meta?: PaginatedMeta }>(
    "/orders",
    { params }
  );

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