import { create } from "zustand";
import { persist } from "zustand/middleware";
import type { Tenant, User } from "@/types/auth";
import { removeToken, setToken } from "@/lib/utils/token";

interface AuthState {
  user: User | null;
  tenant: Tenant | null;
  permissions: string[];
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  requires2fa: boolean;
  pendingEmail: string | null;
  setAuth: (data: {
    user: User;
    tenant: Tenant;
    permissions: string[];
    token: string;
  }) => void;
  setPending2fa: (email: string) => void;
  clearAuth: () => void;
  setLoading: (loading: boolean) => void;
  hasPermission: (permission: string) => boolean;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      tenant: null,
      permissions: [],
      token: null,
      isAuthenticated: false,
      isLoading: false,
      requires2fa: false,
      pendingEmail: null,

      setAuth: ({ user, tenant, permissions, token }) => {
        setToken(token);
        set({
          user,
          tenant,
          permissions,
          token,
          isAuthenticated: true,
          requires2fa: false,
          pendingEmail: null,
        });
      },

      setPending2fa: (email) => {
        set({ requires2fa: true, pendingEmail: email });
      },

      clearAuth: () => {
        removeToken();
        set({
          user: null,
          tenant: null,
          permissions: [],
          token: null,
          isAuthenticated: false,
          requires2fa: false,
          pendingEmail: null,
        });
      },

      setLoading: (loading) => set({ isLoading: loading }),

      hasPermission: (permission) => {
        const { permissions } = get();
        return permissions.includes(permission);
      },
    }),
    {
      name: "creativepos-auth",
      partialize: (state) => ({
        user: state.user,
        tenant: state.tenant,
        permissions: state.permissions,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);