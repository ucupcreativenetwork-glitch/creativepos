export interface User {
  id: number;
  name: string;
  email: string;
  phone?: string;
  roles: string[];
  is_super_admin?: boolean;
  email_verified_at?: string | null;
  created_at?: string;
}

export interface Tenant {
  id: number;
  name: string;
  slug: string;
  logo_url?: string | null;
  status?: string;
}

export interface AuthResponse {
  token: string;
  user: User;
  permissions: string[];
  tenant: Tenant;
  requires_2fa?: boolean;
}

export interface RegisterPayload {
  business_name: string;
  owner_name: string;
  email: string;
  phone: string;
  password: string;
  password_confirmation: string;
  package_slug?: string;
}

export interface LoginPayload {
  email: string;
  password: string;
  device_name?: string;
}

export interface TwoFactorPayload {
  code: string;
}

export interface ForgotPasswordPayload {
  email: string;
}

export interface ResetPasswordPayload {
  token: string;
  email: string;
  password: string;
  password_confirmation: string;
}

export interface OtpWhatsappPayload {
  phone: string;
  purpose: "login" | "register" | "reset";
}

export interface OtpVerifyPayload {
  identifier: string;
  code: string;
  channel: "whatsapp" | "sms";
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  meta?: {
    current_page: number;
    per_page: number;
    total: number;
  };
}

export interface ApiError {
  success: false;
  message: string;
  errors?: Record<string, string[]>;
}

export interface MeResponse {
  user: User;
  tenant: Tenant;
  permissions: string[];
}