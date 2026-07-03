import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";

export interface PlatformDashboard {
  total_tenants: number;
  active_tenants: number;
  trial_tenants: number;
  suspended_tenants: number;
  mrr: number;
  arr: number;
}

export interface PlatformTenant {
  id: number;
  uuid: string;
  name: string;
  slug: string;
  email: string;
  phone?: string | null;
  status: "active" | "suspended" | "trial" | "terminated";
  trial_ends_at?: string | null;
  created_at: string;
  subscription?: {
    package_name: string;
    status: string;
    billing_cycle: string;
  } | null;
}

export async function getPlatformDashboard(): Promise<PlatformDashboard> {
  const { data } = await apiClient.get<ApiResponse<PlatformDashboard>>(
    "/platform/dashboard"
  );
  return data.data;
}

export async function getPlatformTenants(params?: {
  search?: string;
  status?: string;
  page?: number;
  per_page?: number;
}): Promise<PlatformTenant[]> {
  const { data } = await apiClient.get<ApiResponse<PlatformTenant[]>>(
    "/platform/tenants",
    { params }
  );
  return data.data;
}

export async function suspendPlatformTenant(tenantId: number): Promise<PlatformTenant> {
  const { data } = await apiClient.patch<ApiResponse<PlatformTenant>>(
    `/platform/tenants/${tenantId}/suspend`
  );
  return data.data;
}

export async function activatePlatformTenant(tenantId: number): Promise<PlatformTenant> {
  const { data } = await apiClient.patch<ApiResponse<PlatformTenant>>(
    `/platform/tenants/${tenantId}/activate`
  );
  return data.data;
}

export interface AppRelease {
  id: number;
  platform: string;
  version: string;
  build_number: number;
  file_size: number;
  release_notes?: string | null;
  is_mandatory: boolean;
  is_active: boolean;
  download_url: string;
  published_at?: string | null;
}

export async function getAppReleases(): Promise<AppRelease[]> {
  const { data } = await apiClient.get<ApiResponse<AppRelease[]>>(
    "/platform/app-releases"
  );
  return data.data;
}

export async function uploadAppRelease(form: FormData): Promise<AppRelease> {
  const { data } = await apiClient.post<ApiResponse<AppRelease>>(
    "/platform/app-releases",
    form,
    { headers: { "Content-Type": "multipart/form-data" } }
  );
  return data.data;
}

export async function activateAppRelease(id: number): Promise<AppRelease> {
  const { data } = await apiClient.patch<ApiResponse<AppRelease>>(
    `/platform/app-releases/${id}/activate`
  );
  return data.data;
}

export async function deleteAppRelease(id: number): Promise<void> {
  await apiClient.delete(`/platform/app-releases/${id}`);
}

export interface PlatformDevice {
  id: number;
  device_name: string;
  fingerprint: string;
  install_id?: string | null;
  platform?: string | null;
  browser?: string | null;
  app_version?: string | null;
  build_number?: number | null;
  os_version?: string | null;
  device_model?: string | null;
  mac_address?: string | null;
  last_ip?: string | null;
  api_base_url?: string | null;
  agent_version?: string | null;
  remote_agent_enabled: boolean;
  is_online: boolean;
  last_seen_at?: string | null;
  last_used_at?: string | null;
  created_at?: string | null;
  user?: { id: number; name: string; email: string } | null;
  tenant?: { id: number; name: string; slug: string } | null;
}

export interface PlatformDeviceStats {
  total_devices: number;
  online_devices: number;
  android_devices: number;
  web_devices: number;
  pending_commands: number;
}

export interface PlatformDeviceDetail {
  device: PlatformDevice;
  diagnostics: Array<{
    id: number;
    type: string;
    title?: string | null;
    content: string;
    metadata?: Record<string, unknown> | null;
    created_at?: string | null;
  }>;
  commands: Array<{
    id: number;
    command: string;
    status: string;
    payload?: Record<string, unknown> | null;
    result?: string | null;
    created_at?: string | null;
    completed_at?: string | null;
  }>;
}

export async function getPlatformDeviceStats(): Promise<PlatformDeviceStats> {
  const { data } = await apiClient.get<ApiResponse<PlatformDeviceStats>>(
    "/platform/devices/stats",
  );
  return data.data;
}

export async function getPlatformDevices(params?: {
  search?: string;
  platform?: string;
  online_only?: boolean;
  page?: number;
  per_page?: number;
}): Promise<{ items: PlatformDevice[]; total: number }> {
  const { data } = await apiClient.get<
    ApiResponse<PlatformDevice[]> & {
      meta?: { total?: number };
    }
  >("/platform/devices", { params });
  return {
    items: data.data,
    total: data.meta?.total ?? data.data.length,
  };
}

export async function getPlatformDeviceDetail(
  id: number,
): Promise<PlatformDeviceDetail> {
  const { data } = await apiClient.get<ApiResponse<PlatformDeviceDetail>>(
    `/platform/devices/${id}`,
  );
  return data.data;
}

export async function sendPlatformDeviceCommand(
  id: number,
  command: string,
  payload?: Record<string, unknown>,
): Promise<void> {
  await apiClient.post(`/platform/devices/${id}/commands`, {
    command,
    payload,
  });
}