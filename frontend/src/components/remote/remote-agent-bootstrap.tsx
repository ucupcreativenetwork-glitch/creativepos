"use client";

import { useEffect } from "react";
import { useAuthHydrated } from "@/hooks/useAuthHydrated";
import { startRemoteAgent, stopRemoteAgent } from "@/lib/remote/remote-agent";
import { useAuthStore } from "@/stores/auth-store";

export function RemoteAgentBootstrap() {
  const hydrated = useAuthHydrated();
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);

  useEffect(() => {
    if (!hydrated) return;

    if (isAuthenticated) {
      startRemoteAgent();
      return () => stopRemoteAgent();
    }

    stopRemoteAgent();
    return undefined;
  }, [hydrated, isAuthenticated]);

  return null;
}