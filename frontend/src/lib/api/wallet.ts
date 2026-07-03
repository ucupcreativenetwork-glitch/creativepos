import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { PaginatedMeta, WalletTransaction } from "@/types/loyalty";

export async function getWallet(memberUuid: string): Promise<{
  member_id: number;
  balance: number;
  lifetime_topup: number;
  lifetime_spent: number;
  status: string;
}> {
  const { data } = await apiClient.get<
    ApiResponse<{
      member_id: number;
      balance: number;
      lifetime_topup: number;
      lifetime_spent: number;
      status: string;
    }>
  >(`/wallet/${memberUuid}`);
  return data.data;
}

export async function getWalletTransactions(
  memberUuid: string,
  page = 1
): Promise<{ data: WalletTransaction[]; meta: PaginatedMeta }> {
  const { data } = await apiClient.get<
    ApiResponse<WalletTransaction[]> & { meta?: PaginatedMeta }
  >(`/wallet/${memberUuid}/transactions`, { params: { page } });

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

export async function topupWallet(
  memberId: number,
  amount: number,
  description?: string
): Promise<{ balance: number }> {
  const { data } = await apiClient.post<ApiResponse<{ balance: number }>>(
    "/wallet/topup",
    { member_id: memberId, amount, description }
  );
  return data.data;
}

export async function withdrawWallet(
  memberId: number,
  amount: number,
  description?: string
): Promise<{ balance: number }> {
  const { data } = await apiClient.post<ApiResponse<{ balance: number }>>(
    "/wallet/withdraw",
    { member_id: memberId, amount, description }
  );
  return data.data;
}

export async function transferWallet(
  fromMemberId: number,
  toMemberId: number,
  amount: number,
  description?: string
): Promise<{ from_balance: number; to_balance: number }> {
  const { data } = await apiClient.post<
    ApiResponse<{ from_balance: number; to_balance: number }>
  >("/wallet/transfer", {
    from_member_id: fromMemberId,
    to_member_id: toMemberId,
    amount,
    description,
  });
  return data.data;
}