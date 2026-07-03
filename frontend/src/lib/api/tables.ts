import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";

export interface RestaurantTable {
  id: number;
  outlet_id: number;
  outlet?: { id: number; name: string; code: string } | null;
  table_number: string;
  name?: string | null;
  capacity: number;
  status: "available" | "occupied" | "reserved" | "cleaning";
  is_active: boolean;
  qr_token?: string | null;
}

export interface TableQrResult {
  qr_token: string;
  menu_url: string;
  table_id: number;
}

export async function getTables(params?: {
  outlet_id?: number;
}): Promise<RestaurantTable[]> {
  const { data } = await apiClient.get<ApiResponse<RestaurantTable[]>>(
    "/tables",
    { params }
  );
  return data.data;
}

export async function createTable(payload: {
  outlet_id: number;
  table_number: string;
  name?: string;
  capacity: number;
  is_active?: boolean;
}): Promise<RestaurantTable> {
  const { data } = await apiClient.post<ApiResponse<RestaurantTable>>(
    "/tables",
    payload
  );
  return data.data;
}

export async function updateTable(
  id: number,
  payload: Partial<{
    table_number: string;
    name: string;
    capacity: number;
    status: RestaurantTable["status"];
    is_active: boolean;
  }>
): Promise<RestaurantTable> {
  const { data } = await apiClient.put<ApiResponse<RestaurantTable>>(
    `/tables/${id}`,
    payload
  );
  return data.data;
}

export async function generateTableQr(id: number): Promise<TableQrResult> {
  const { data } = await apiClient.post<ApiResponse<TableQrResult>>(
    `/tables/${id}/qr`
  );
  return data.data;
}