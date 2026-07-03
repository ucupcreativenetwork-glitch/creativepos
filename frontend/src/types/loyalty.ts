export interface MemberTier {
  id: number;
  name: string;
  slug: string;
  point_multiplier?: number;
}

export interface MemberPoints {
  balance: number;
  lifetime_earned: number;
  lifetime_redeemed: number;
}

export interface MemberWallet {
  balance: number;
  lifetime_topup: number;
  lifetime_spent: number;
  status: string;
}

export interface Member {
  id: number;
  uuid: string;
  member_code: string;
  qr_token?: string;
  name: string;
  email?: string | null;
  phone: string;
  birthday?: string | null;
  status: "active" | "inactive" | "blocked";
  total_spend: number;
  visit_count: number;
  last_visit_at?: string | null;
  tier?: MemberTier | null;
  points?: MemberPoints | null;
  wallet?: MemberWallet | null;
  created_at?: string;
}

export interface MemberPayload {
  name: string;
  phone: string;
  email?: string;
  birthday?: string;
  status?: string;
}

export interface PointTransaction {
  id: number;
  type: string;
  points: number;
  balance_after: number;
  description?: string | null;
  created_at?: string;
}

export interface PointBalance {
  balance: number;
  lifetime_earned: number;
  lifetime_redeemed: number;
  config?: {
    earn_amount: number;
    earn_points: number;
    redeem_points: number;
    redeem_value: number;
    min_redeem_points: number;
  } | null;
  history?: PointTransaction[];
  meta?: {
    current_page: number;
    per_page: number;
    total: number;
    last_page: number;
  };
}

export interface WalletTransaction {
  id: number;
  type: string;
  amount: number;
  balance_before: number;
  balance_after: number;
  description?: string | null;
  created_at?: string;
}

export interface TierConfig {
  id: number;
  name: string;
  slug: string;
  min_spend: number;
  point_multiplier: number;
}

export interface PaginatedMeta {
  current_page: number;
  per_page: number;
  total: number;
  last_page: number;
}