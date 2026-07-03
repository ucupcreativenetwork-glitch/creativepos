import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { PaginatedMeta } from "@/types/loyalty";
import type {
  CalculateFeePayload,
  CreateDeliveryOrderPayload,
  DeliveryDriver,
  DeliveryOrder,
  DeliveryZone,
  FeeCalculation,
} from "@/types/delivery";

interface PaginatedResponse<T> {
  data: T[];
  meta: PaginatedMeta;
}

export async function getDeliveryOrders(params?: {
  outlet_id?: number;
  status?: string;
  driver_id?: number;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<DeliveryOrder>> {
  const { data } = await apiClient.get<
    ApiResponse<DeliveryOrder[]> & { meta?: PaginatedMeta }
  >("/delivery/orders", { params });

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

export async function getDeliveryOrder(uuid: string): Promise<DeliveryOrder> {
  const { data } = await apiClient.get<ApiResponse<DeliveryOrder>>(
    `/delivery/orders/${uuid}`
  );
  return data.data;
}

function toApiOrderPayload(payload: CreateDeliveryOrderPayload) {
  return {
    outlet_id: payload.outlet_id,
    delivery_zone_id: payload.zone_id,
    customer_name: payload.customer_name,
    customer_phone: payload.customer_phone,
    delivery_address: payload.address.address,
    delivery_notes: payload.notes,
    distance_km: payload.distance_km,
    shipping_fee: payload.shipping_fee,
    estimated_minutes: payload.estimated_minutes,
    items: payload.items,
  };
}

export async function createDeliveryOrder(
  payload: CreateDeliveryOrderPayload
): Promise<DeliveryOrder> {
  const { data } = await apiClient.post<ApiResponse<DeliveryOrder>>(
    "/delivery/orders",
    toApiOrderPayload(payload)
  );
  return data.data;
}

export async function updateDeliveryStatus(
  uuid: string,
  status: string
): Promise<DeliveryOrder> {
  const { data } = await apiClient.patch<ApiResponse<DeliveryOrder>>(
    `/delivery/orders/${uuid}/status`,
    { status }
  );
  return data.data;
}

export async function assignDriver(
  uuid: string,
  driverId: number
): Promise<DeliveryOrder> {
  const { data } = await apiClient.post<ApiResponse<DeliveryOrder>>(
    `/delivery/orders/${uuid}/assign`,
    { driver_id: driverId }
  );
  return data.data;
}

export async function getDrivers(params?: {
  available_only?: boolean;
}): Promise<DeliveryDriver[]> {
  const { data } = await apiClient.get<ApiResponse<DeliveryDriver[]>>(
    "/delivery/drivers",
    { params }
  );
  return data.data;
}

export async function getZones(params?: {
  outlet_id?: number;
}): Promise<DeliveryZone[]> {
  const { data } = await apiClient.get<ApiResponse<DeliveryZone[]>>(
    "/delivery/zones",
    { params }
  );
  return data.data;
}

export async function calculateFee(
  payload: CalculateFeePayload
): Promise<FeeCalculation> {
  const { data } = await apiClient.post<ApiResponse<FeeCalculation>>(
    "/delivery/calculate-fee",
    {
      zone_id: payload.zone_id,
      distance_km: payload.distance_km,
    }
  );
  const result = data.data as FeeCalculation & {
    zone?: { id: number; name: string };
  };
  return {
    zone_id: result.zone_id ?? result.zone?.id ?? payload.zone_id,
    zone_name: result.zone_name ?? result.zone?.name,
    distance_km: result.distance_km,
    shipping_fee: result.shipping_fee,
    estimated_minutes: result.estimated_minutes,
  };
}

export async function createDeliveryZone(payload: {
  outlet_id: number;
  name: string;
  code: string;
  base_fee: number;
  fee_per_km?: number;
  max_distance_km?: number;
}): Promise<DeliveryZone> {
  const { data } = await apiClient.post<ApiResponse<DeliveryZone>>(
    "/delivery/zones",
    payload
  );
  return data.data;
}

export async function createDeliveryDriver(payload: {
  user_id: number;
  outlet_id?: number;
  vehicle_type?: string;
  vehicle_plate?: string;
}): Promise<DeliveryDriver> {
  const { data } = await apiClient.post<ApiResponse<DeliveryDriver>>(
    "/delivery/drivers",
    payload
  );
  return data.data;
}