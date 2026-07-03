import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";

export interface PointConfig {
  earn_amount: number;
  earn_points: number;
  redeem_points: number;
  redeem_value: number;
  min_redeem_points: number;
  point_expiry_days?: number | null;
  is_active: boolean;
}

export async function getPointConfig(): Promise<PointConfig> {
  const { data } = await apiClient.get<ApiResponse<PointConfig>>(
    "/loyalty/point-config"
  );
  return data.data;
}

export async function updatePointConfig(
  payload: Partial<PointConfig>
): Promise<PointConfig> {
  const { data } = await apiClient.put<ApiResponse<PointConfig>>(
    "/loyalty/point-config",
    payload
  );
  return data.data;
}

export interface TierConfigItem {
  id: number;
  name: string;
  slug: string;
  min_spend: number;
  point_multiplier: number;
  is_active?: boolean;
}

export async function updateTier(
  id: number,
  payload: Partial<{
    name: string;
    min_spend: number;
    point_multiplier: number;
    is_active: boolean;
  }>
): Promise<TierConfigItem> {
  const { data } = await apiClient.put<ApiResponse<TierConfigItem>>(
    `/loyalty/tiers/${id}`,
    payload
  );
  return data.data;
}