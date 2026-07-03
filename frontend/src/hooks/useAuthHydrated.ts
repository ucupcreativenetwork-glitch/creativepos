"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/stores/auth-store";

export function useAuthHydrated(): boolean {
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    const persist = useAuthStore.persist;
    if (!persist?.rehydrate) {
      setHydrated(true);
      return;
    }

    const unsub = persist.onFinishHydration(() => {
      setHydrated(true);
    });

    if (persist.hasHydrated()) {
      setHydrated(true);
    } else {
      void persist.rehydrate();
    }

    return unsub;
  }, []);

  return hydrated;
}