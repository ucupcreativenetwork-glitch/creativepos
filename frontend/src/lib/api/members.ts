import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type {
  Member,
  MemberPayload,
  PaginatedMeta,
  PointBalance,
  TierConfig,
} from "@/types/loyalty";

interface PaginatedResponse<T> {
  data: T[];
  meta: PaginatedMeta;
}

export async function getMembers(params?: {
  search?: string;
  status?: string;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<Member>> {
  const { data } = await apiClient.get<ApiResponse<Member[]> & { meta?: PaginatedMeta }>(
    "/members",
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

export async function getMember(uuid: string): Promise<Member> {
  const { data } = await apiClient.get<ApiResponse<Member>>(`/members/${uuid}`);
  return data.data;
}

export async function findMemberByCode(code: string): Promise<Member> {
  const { data } = await apiClient.get<ApiResponse<Member>>(`/members/code/${code}`);
  return data.data;
}

export async function createMember(payload: MemberPayload): Promise<Member> {
  const { data } = await apiClient.post<ApiResponse<Member>>("/members", payload);
  return data.data;
}

export async function updateMember(
  uuid: string,
  payload: Partial<MemberPayload>
): Promise<Member> {
  const { data } = await apiClient.put<ApiResponse<Member>>(`/members/${uuid}`, payload);
  return data.data;
}

export async function getMemberPoints(uuid: string): Promise<PointBalance> {
  const { data } = await apiClient.get<ApiResponse<PointBalance>>(
    `/members/${uuid}/points`
  );
  return data.data;
}

export async function adjustMemberPoints(
  uuid: string,
  points: number,
  description: string
): Promise<PointBalance> {
  const { data } = await apiClient.post<ApiResponse<PointBalance>>(
    `/members/${uuid}/points/adjust`,
    { points, description }
  );
  return data.data;
}

export async function redeemPoints(
  uuid: string,
  points: number,
  description?: string
): Promise<{ points_redeemed: number; balance_after: number; discount_value: number }> {
  const { data } = await apiClient.post<
    ApiResponse<{ points_redeemed: number; balance_after: number; discount_value: number }>
  >(`/members/${uuid}/points/redeem`, { points, description });
  return data.data;
}

export async function getTiers(): Promise<TierConfig[]> {
  const { data } = await apiClient.get<ApiResponse<TierConfig[]>>("/members/tiers");
  return data.data;
}