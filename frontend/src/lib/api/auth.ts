import { apiClient } from "@/lib/api/client";
import { setToken, removeToken } from "@/lib/utils/token";
import type {
  ApiResponse,
  AuthResponse,
  ChangePasswordPayload,
  ForgotPasswordPayload,
  LoginPayload,
  MeResponse,
  OtpVerifyPayload,
  OtpWhatsappPayload,
  RegisterPayload,
  ResetPasswordPayload,
  TwoFactorPayload,
  User,
} from "@/types/auth";

export async function register(
  payload: RegisterPayload
): Promise<AuthResponse> {
  const { data } = await apiClient.post<ApiResponse<AuthResponse>>(
    "/auth/register",
    payload
  );
  if (data.data.token) {
    setToken(data.data.token);
  }
  return data.data;
}

export async function login(payload: LoginPayload): Promise<AuthResponse> {
  const { data } = await apiClient.post<ApiResponse<AuthResponse>>(
    "/auth/login",
    {
      ...payload,
      device_name: payload.device_name ?? "CreativePOS Web",
    }
  );
  if (data.data.token && !data.data.requires_2fa) {
    setToken(data.data.token);
  }
  return data.data;
}

export async function login2fa(payload: TwoFactorPayload): Promise<AuthResponse> {
  const { data } = await apiClient.post<ApiResponse<AuthResponse>>(
    "/auth/login/2fa",
    payload
  );
  if (data.data.token) {
    setToken(data.data.token);
  }
  return data.data;
}

export async function forgotPassword(
  payload: ForgotPasswordPayload
): Promise<void> {
  await apiClient.post("/auth/forgot-password", payload);
}

export async function resetPassword(
  payload: ResetPasswordPayload
): Promise<void> {
  await apiClient.post("/auth/reset-password", payload);
}

export async function sendOtpWhatsapp(
  payload: OtpWhatsappPayload
): Promise<{ expires_in: number }> {
  const { data } = await apiClient.post<
    ApiResponse<{ expires_in: number }>
  >("/auth/otp/whatsapp", payload);
  return data.data;
}

export async function verifyOtp(
  payload: OtpVerifyPayload
): Promise<AuthResponse> {
  const { data } = await apiClient.post<ApiResponse<AuthResponse>>(
    "/auth/otp/verify",
    payload
  );
  if (data.data.token) {
    setToken(data.data.token);
  }
  return data.data;
}

export async function getMe(): Promise<MeResponse> {
  const { data } = await apiClient.get<ApiResponse<MeResponse>>("/auth/me");
  return data.data;
}

export async function changePassword(
  payload: ChangePasswordPayload,
): Promise<User> {
  const { data } = await apiClient.post<ApiResponse<User>>(
    "/auth/change-password",
    payload,
  );

  return data.data;
}

export async function logout(): Promise<void> {
  try {
    await apiClient.post("/auth/logout");
  } finally {
    removeToken();
  }
}

export async function inviteUser(payload: {
  email: string;
  name?: string;
  role: "cashier" | "manager";
}): Promise<{
  user: { id: number; uuid: string; name: string; email: string; role: string };
  temporary_password: string;
  message: string;
}> {
  const { data } = await apiClient.post<
    ApiResponse<{
      user: {
        id: number;
        uuid: string;
        name: string;
        email: string;
        role: string;
      };
      temporary_password: string;
      message: string;
    }>
  >("/auth/invite", payload);
  return data.data;
}