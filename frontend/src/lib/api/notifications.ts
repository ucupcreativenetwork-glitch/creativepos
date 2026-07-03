import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { PaginatedMeta } from "@/types/loyalty";

export interface AppNotification {
  id: number;
  type: string;
  title: string;
  body: string;
  data?: Record<string, unknown> | null;
  read_at?: string | null;
  created_at?: string;
}

export interface NotificationPreference {
  event: string;
  channels: string[];
  is_enabled: boolean;
}

export async function getNotifications(params?: {
  page?: number;
  per_page?: number;
}): Promise<{ data: AppNotification[]; meta: PaginatedMeta; unread_count: number }> {
  const { data } = await apiClient.get<
    ApiResponse<AppNotification[]> & {
      meta?: PaginatedMeta & { unread_count?: number };
    }
  >("/notifications", { params });

  return {
    data: data.data,
    meta: data.meta ?? {
      current_page: 1,
      per_page: data.data.length,
      total: data.data.length,
      last_page: 1,
    },
    unread_count: data.meta?.unread_count ?? 0,
  };
}

export async function getUnreadNotificationCount(): Promise<number> {
  const { data } = await apiClient.get<ApiResponse<{ count: number }>>(
    "/notifications/unread-count"
  );
  return data.data.count;
}

export async function markNotificationRead(id: number): Promise<void> {
  await apiClient.patch(`/notifications/${id}/read`);
}

export async function markAllNotificationsRead(): Promise<number> {
  const { data } = await apiClient.post<ApiResponse<{ updated: number }>>(
    "/notifications/read-all"
  );
  return data.data.updated;
}

export async function getNotificationPreferences(): Promise<NotificationPreference[]> {
  const { data } = await apiClient.get<ApiResponse<NotificationPreference[]>>(
    "/notifications/preferences"
  );
  return data.data;
}

export async function updateNotificationPreferences(
  preferences: NotificationPreference[]
): Promise<NotificationPreference[]> {
  const { data } = await apiClient.put<ApiResponse<NotificationPreference[]>>(
    "/notifications/preferences",
    { preferences }
  );
  return data.data;
}