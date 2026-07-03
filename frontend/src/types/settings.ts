export interface TenantSettings {
  business_name?: string | null;
  business_type?: string | null;
  phone?: string | null;
  address?: string | null;
  email?: string | null;
  logo_url?: string | null;
  primary_color?: string;
  service_charge_rate?: number;
  tax_rate?: number;
  timezone?: string;
  currency?: string;
  setup_completed?: boolean;
  feature_reservations?: boolean;
  feature_delivery?: boolean;
  feature_qr_menu?: boolean;
  wifi_ssid?: string | null;
  wifi_password?: string | null;
  receipt_show_wifi?: boolean;
  enabled_payment_methods?: string[];
  onboarding_progress?: Record<string, unknown>;
}

export interface TenantSettingsPayload {
  business_name?: string;
  business_type?: string;
  phone?: string;
  address?: string;
  email?: string;
  logo_url?: string;
  primary_color?: string;
  service_charge_rate?: number;
  tax_rate?: number;
  timezone?: string;
  setup_completed?: boolean;
  feature_reservations?: boolean;
  feature_delivery?: boolean;
  feature_qr_menu?: boolean;
  wifi_ssid?: string;
  wifi_password?: string;
  receipt_show_wifi?: boolean;
  onboarding_progress?: Record<string, unknown>;
}

export interface SettingsOutlet {
  id: number;
  uuid: string;
  name: string;
  code: string;
  address?: string | null;
  phone?: string | null;
  is_active: boolean;
  is_default: boolean;
  created_at?: string;
}

export interface IntegrationProvider {
  provider: "email" | "whatsapp" | "midtrans" | "xendit" | "google_maps";
  is_active: boolean;
  config?: Record<string, string | boolean | number>;
}

export interface EmailIntegrationConfig {
  mailer?: "smtp" | "log";
  host?: string;
  port?: number;
  encryption?: "tls" | "ssl" | "none" | null;
  username?: string;
  password?: string;
  from_address?: string;
  from_name?: string;
  send_welcome_email?: boolean;
  is_active?: boolean;
}

export interface EmailTestResult {
  success: boolean;
  mode: "log" | "smtp" | "disabled";
  message: string;
}

export interface WhatsappIntegrationConfig {
  phone_number_id?: string;
  phone?: string;
  access_token?: string;
  webhook_verify_token?: string;
  gateway?: "fonnte" | "wablas" | "meta";
  api_url?: string;
  is_active?: boolean;
}

export interface WhatsappTestResult {
  success: boolean;
  mode: "dev" | "live";
  message: string;
  response?: unknown;
}

export interface SubscriptionInfo {
  id: number;
  status: "active" | "past_due" | "suspended" | "cancelled" | "expired" | "trial";
  billing_cycle: "monthly" | "yearly";
  starts_at: string;
  ends_at: string;
  next_billing_date?: string | null;
  trial_ends_at?: string | null;
  cancelled_at?: string | null;
  package: {
    id: number;
    name: string;
    slug: string;
    description?: string;
    price_monthly: number;
    price_yearly: number;
    features?: Record<string, string>;
  };
}

export interface SettingsUser {
  id: number;
  name: string;
  email: string;
  phone?: string | null;
  status: string;
  outlet?: { id: number; name: string } | null;
  roles?: { id: number; name: string }[];
}

export interface BillingInvoice {
  id: number;
  invoice_number: string;
  amount: number;
  tax_amount: number;
  total_amount: number;
  status: "draft" | "sent" | "paid" | "overdue" | "cancelled";
  payment_gateway?: string | null;
  payment_method?: string | null;
  payment_status?: string | null;
  payment_url?: string | null;
  due_date: string;
  paid_at?: string | null;
  period_start: string;
  period_end: string;
  created_at?: string;
}

export interface BillingPaymentMethod {
  code: string;
  label: string;
  gateway: "midtrans" | "xendit" | "cod";
  recurring: boolean;
}

export interface BillingPaymentInstructions {
  provider?: string;
  method?: string;
  va_number?: string;
  bank?: string;
  qr_string?: string;
  qr_url?: string;
  deeplink?: string;
  biller_code?: string;
  bill_key?: string;
  message?: string;
  recurring?: boolean;
  mode?: string;
  expires_at?: string;
}

export interface BillingPaymentResult {
  invoice_id: number;
  invoice_number: string;
  total_amount: number;
  status: string;
  payment_gateway?: string | null;
  payment_method?: string | null;
  payment_status?: string | null;
  payment_url?: string | null;
  payment_instructions?: BillingPaymentInstructions | null;
  payment_expires_at?: string | null;
  gateway_order_id?: string | null;
}