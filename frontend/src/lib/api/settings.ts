import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { OnboardingStatus } from "@/types/onboarding";
import type { PaginatedMeta } from "@/types/loyalty";
import type {
  EmailIntegrationConfig,
  EmailTestResult,
  IntegrationProvider,
  SettingsOutlet,
  SettingsUser,
  TenantSettings,
  TenantSettingsPayload,
  WhatsappIntegrationConfig,
  WhatsappTestResult,
} from "@/types/settings";

export async function getTenantSettings(): Promise<TenantSettings> {
  const { data } = await apiClient.get<ApiResponse<TenantSettings>>(
    "/settings/tenant"
  );
  return data.data;
}

export async function updateTenantSettings(
  payload: TenantSettingsPayload
): Promise<TenantSettings> {
  const { data } = await apiClient.put<ApiResponse<TenantSettings>>(
    "/settings/tenant",
    payload
  );
  return data.data;
}

export async function getSettingsOutlets(): Promise<SettingsOutlet[]> {
  const { data } = await apiClient.get<ApiResponse<SettingsOutlet[]>>(
    "/settings/outlets"
  );
  return data.data;
}

export async function createOutlet(payload: {
  name: string;
  code: string;
  address?: string;
  phone?: string;
  is_active?: boolean;
  is_default?: boolean;
}): Promise<SettingsOutlet> {
  const { data } = await apiClient.post<ApiResponse<SettingsOutlet>>(
    "/settings/outlets",
    payload
  );
  return data.data;
}

export async function updateOutlet(
  outletUuid: string,
  payload: Partial<{
    name: string;
    code: string;
    address: string;
    phone: string;
    is_active: boolean;
    is_default: boolean;
  }>
): Promise<SettingsOutlet> {
  const { data } = await apiClient.put<ApiResponse<SettingsOutlet>>(
    `/settings/outlets/${outletUuid}`,
    payload
  );
  return data.data;
}

export interface OnboardingChecklistItem {
  id: string;
  label: string;
  description: string;
  done: boolean;
  href: string;
  priority: number;
}

export interface OnboardingChecklist {
  setup_completed: boolean;
  items: OnboardingChecklistItem[];
  completed_count: number;
  total_count: number;
  progress_percent: number;
  quota?: {
    limits: { max_outlets: number; max_users: number; max_products: number } | null;
    usage: { outlets: number; users: number; products: number };
    remaining: {
      outlets: number | null;
      users: number | null;
      products: number | null;
    } | null;
  };
}

export async function getOnboardingChecklist(): Promise<OnboardingChecklist> {
  const { data } = await apiClient.get<ApiResponse<OnboardingChecklist>>(
    "/settings/onboarding-checklist"
  );
  return data.data;
}

export async function getOnboardingStatus(): Promise<OnboardingStatus> {
  const { data } = await apiClient.get<ApiResponse<OnboardingStatus>>(
    "/settings/onboarding-status"
  );
  return data.data;
}

export async function updateOnboardingProgress(payload: {
  current_step?: number;
  completed_steps?: string[];
  skipped_steps?: string[];
  staff_invited?: boolean;
}): Promise<OnboardingStatus> {
  const { data } = await apiClient.patch<ApiResponse<OnboardingStatus>>(
    "/settings/onboarding-progress",
    payload
  );
  return data.data;
}

export async function syncPaymentMethods(codes: string[]): Promise<{
  enabled_codes: string[];
  methods: { id: number; code: string; name: string; type: string }[];
}> {
  const { data } = await apiClient.post<
    ApiResponse<{
      enabled_codes: string[];
      methods: { id: number; code: string; name: string; type: string }[];
    }>
  >("/settings/payment-methods", { codes });
  return data.data;
}

export async function completeSetup(): Promise<TenantSettings> {
  return updateTenantSettings({
    setup_completed: true,
    onboarding_progress: {
      completed_at: new Date().toISOString(),
    },
  });
}

export async function getSettingsUsers(params?: {
  page?: number;
  per_page?: number;
}): Promise<{ data: SettingsUser[]; meta: PaginatedMeta }> {
  const { data } = await apiClient.get<
    ApiResponse<SettingsUser[]> & { meta?: PaginatedMeta }
  >("/settings/users", { params });

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

export async function getIntegrations(): Promise<IntegrationProvider[]> {
  const { data } = await apiClient.get<ApiResponse<IntegrationProvider[]>>(
    "/settings/integrations"
  );
  return data.data;
}

export async function updateEmailIntegration(
  config: EmailIntegrationConfig
): Promise<IntegrationProvider> {
  const { data } = await apiClient.put<ApiResponse<IntegrationProvider>>(
    "/settings/integrations/email",
    { config, is_active: config.is_active ?? false }
  );
  return data.data;
}

export async function testEmailIntegration(payload: {
  email: string;
  mailer?: "smtp" | "log";
  host?: string;
  port?: number;
  encryption?: "tls" | "ssl" | "none";
  username?: string;
  password?: string;
  from_address?: string;
  from_name?: string;
  is_active?: boolean;
  send_welcome_email?: boolean;
  save_config?: boolean;
}): Promise<EmailTestResult> {
  const { data } = await apiClient.post<ApiResponse<EmailTestResult>>(
    "/settings/integrations/email/test",
    payload
  );
  return data.data;
}

export async function updateWhatsappIntegration(
  config: WhatsappIntegrationConfig
): Promise<IntegrationProvider> {
  const { data } = await apiClient.put<ApiResponse<IntegrationProvider>>(
    "/settings/integrations/whatsapp",
    { config, is_active: config.is_active ?? false }
  );
  return data.data;
}

export async function testWhatsappIntegration(payload: {
  phone: string;
  message?: string;
  gateway?: "fonnte" | "wablas" | "meta";
  api_token?: string;
  access_token?: string;
  api_url?: string;
  sender_phone?: string;
  is_active?: boolean;
  save_config?: boolean;
}): Promise<WhatsappTestResult> {
  const { data } = await apiClient.post<ApiResponse<WhatsappTestResult>>(
    "/settings/integrations/whatsapp/test",
    payload
  );
  return data.data;
}