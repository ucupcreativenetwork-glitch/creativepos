import axios from "axios";
import type { ApiResponse } from "@/types/auth";
import type { DigitalMenu, Order, OrderTrack } from "@/types/order";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://10.110.1.15:8000/api/v1";

const publicClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
  timeout: 30000,
});

export async function getPublicMenu(
  tenantSlug: string,
  outletSlug: string
): Promise<DigitalMenu> {
  const { data } = await publicClient.get<ApiResponse<DigitalMenu>>(
    `/public/menu/${tenantSlug}/${outletSlug}`
  );
  return data.data;
}

export async function getTableMenu(
  tenantSlug: string,
  outletSlug: string,
  token: string
): Promise<DigitalMenu> {
  const { data } = await publicClient.get<ApiResponse<DigitalMenu>>(
    `/public/menu/${tenantSlug}/${outletSlug}/table/${token}`
  );
  return data.data;
}

export async function submitPublicOrder(payload: {
  tenant_slug: string;
  outlet_slug: string;
  table_token?: string;
  notes?: string;
  items: { product_id: number; quantity: number; notes?: string }[];
}): Promise<Order> {
  const { data } = await publicClient.post<ApiResponse<Order>>(
    "/public/orders",
    payload
  );
  return data.data;
}

export async function trackOrder(uuid: string): Promise<OrderTrack> {
  const { data } = await publicClient.get<ApiResponse<OrderTrack>>(
    `/public/orders/${uuid}/track`
  );
  return data.data;
}

export async function callWaiter(payload: {
  tenant_slug: string;
  outlet_slug: string;
  table_token: string;
}): Promise<void> {
  await publicClient.post("/public/call-waiter", payload);
}

export async function requestBill(payload: {
  tenant_slug: string;
  outlet_slug: string;
  table_token: string;
}): Promise<void> {
  await publicClient.post("/public/request-bill", payload);
}