import axios, {
  type AxiosError,
  type AxiosInstance,
  type InternalAxiosRequestConfig,
} from "axios";
import { getToken, removeToken } from "@/lib/utils/token";
import type { ApiError } from "@/types/auth";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://10.110.1.15:8000/api/v1";

export const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
  timeout: 30000,
});

apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = getToken();
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError<ApiError>) => {
    if (error.response?.status === 401) {
      removeToken();
      if (
        typeof window !== "undefined" &&
        !window.location.pathname.startsWith("/login")
      ) {
        window.location.href = "/login";
      }
    }

    if (error.response?.status === 403 && typeof window !== "undefined") {
      const payload = error.response?.data as { message?: string; code?: string } | undefined;
      const message = payload?.message ?? "";

      if (payload?.code === "PASSWORD_CHANGE_REQUIRED") {
        if (!window.location.pathname.startsWith("/change-password")) {
          window.location.href = "/change-password";
        }
      } else if (message.includes("not available") || message.includes("tidak tersedia")) {
        error.message =
          message ||
          "Fitur ini tidak tersedia di paket langganan Anda. Upgrade paket di Pengaturan.";
      }
    }

    return Promise.reject(error);
  }
);

export function getErrorMessage(error: unknown): string {
  if (axios.isAxiosError<ApiError>(error)) {
    const apiError = error.response?.data;
    if (apiError?.errors) {
      const firstError = Object.values(apiError.errors)[0];
      if (firstError?.[0]) return firstError[0];
    }
    if (apiError?.message) return apiError.message;
    if (error.message) return error.message;
  }
  if (error instanceof Error) return error.message;
  return "Terjadi kesalahan. Silakan coba lagi.";
}

export function getFieldErrors(error: unknown): Record<string, string> {
  if (axios.isAxiosError<ApiError>(error) && error.response?.data?.errors) {
    const errors = error.response.data.errors;
    return Object.fromEntries(
      Object.entries(errors).map(([key, messages]) => [key, messages[0] ?? ""])
    );
  }
  return {};
}