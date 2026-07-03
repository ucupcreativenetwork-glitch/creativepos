"use client";

import { useCallback, useEffect, useState } from "react";
import { getOnboardingStatus } from "@/lib/api/settings";
import type {
  OnboardingLocalProgress,
  OnboardingStepId,
  OutletStepData,
  PaymentStepData,
  ProductStepData,
  ProfileStepData,
  StaffStepData,
} from "@/types/onboarding";

export const ONBOARDING_STORAGE_KEY = "creativepos_onboarding_progress";

export const DEFAULT_PROFILE: ProfileStepData = {
  business_name: "",
  business_type: "",
  logo_url: "",
  address: "",
  phone: "",
};

export const DEFAULT_OUTLET: OutletStepData = {
  outlet_id: null,
  outlet_uuid: null,
  name: "",
  code: "",
  timezone: "Asia/Jakarta",
  feature_reservations: true,
  feature_delivery: true,
  feature_qr_menu: true,
};

export const DEFAULT_PRODUCT: ProductStepData = {
  name: "",
  base_price: "",
  category_name: "",
  image_url: "",
};

export const DEFAULT_PAYMENT: PaymentStepData = {
  selected: ["cash"],
};

export const DEFAULT_STAFF: StaffStepData = {
  email: "",
  name: "",
  role: "cashier",
};

export function createDefaultProgress(): OnboardingLocalProgress {
  return {
    currentStep: 1,
    profile: { ...DEFAULT_PROFILE },
    outlet: { ...DEFAULT_OUTLET },
    product: { ...DEFAULT_PRODUCT },
    payment: { ...DEFAULT_PAYMENT },
    staff: { ...DEFAULT_STAFF },
    skippedSteps: [],
  };
}

function readStoredProgress(): OnboardingLocalProgress | null {
  if (typeof window === "undefined") return null;

  try {
    const raw = localStorage.getItem(ONBOARDING_STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as OnboardingLocalProgress;
    if (parsed.profile?.logo_url?.startsWith("data:")) {
      parsed.profile.logo_url = "";
    }
    return parsed;
  } catch {
    return null;
  }
}

function stepFromServer(
  completed: OnboardingStepId[],
  skipped: OnboardingStepId[],
): number {
  const order: OnboardingStepId[] = [
    "profile",
    "outlet",
    "product",
    "payment",
    "staff",
  ];

  for (let i = 0; i < order.length; i += 1) {
    const step = order[i];
    if (!completed.includes(step) && !skipped.includes(step)) {
      return i + 1;
    }
  }

  return 5;
}

export function useOnboardingWizard(enabled: boolean) {
  const [progress, setProgress] = useState<OnboardingLocalProgress>(
    createDefaultProgress,
  );
  const [isHydrated, setIsHydrated] = useState(false);
  const [isLoading, setIsLoading] = useState(enabled);

  useEffect(() => {
    if (!enabled) {
      setIsHydrated(true);
      setIsLoading(false);
      return;
    }

    let cancelled = false;

    async function hydrate() {
      const stored = readStoredProgress();
      if (stored) {
        setProgress(stored);
      }

      try {
        const status = await getOnboardingStatus();
        if (cancelled) return;

        setProgress((prev) => {
          const serverStep = status.current_step || stepFromServer(
            status.completed_steps,
            status.skipped_steps,
          );
          const localStep = stored?.currentStep ?? prev.currentStep;
          const mergedStep = Math.max(serverStep, localStep, 1);

          return {
            ...prev,
            ...(stored ?? {}),
            currentStep: Math.min(mergedStep, 5),
            skippedSteps: [
              ...new Set([
                ...(stored?.skippedSteps ?? []),
                ...status.skipped_steps,
              ]),
            ],
          };
        });
      } catch {
        // Keep local progress if API unavailable
      } finally {
        if (!cancelled) {
          setIsHydrated(true);
          setIsLoading(false);
        }
      }
    }

    hydrate();

    return () => {
      cancelled = true;
    };
  }, [enabled]);

  useEffect(() => {
    if (!isHydrated || typeof window === "undefined") return;
    localStorage.setItem(ONBOARDING_STORAGE_KEY, JSON.stringify(progress));
  }, [progress, isHydrated]);

  const setCurrentStep = useCallback((step: number) => {
    setProgress((prev) => ({ ...prev, currentStep: step }));
  }, []);

  const updateProfile = useCallback((data: Partial<ProfileStepData>) => {
    setProgress((prev) => ({
      ...prev,
      profile: { ...prev.profile, ...data },
    }));
  }, []);

  const updateOutlet = useCallback((data: Partial<OutletStepData>) => {
    setProgress((prev) => ({
      ...prev,
      outlet: { ...prev.outlet, ...data },
    }));
  }, []);

  const updateProduct = useCallback((data: Partial<ProductStepData>) => {
    setProgress((prev) => ({
      ...prev,
      product: { ...prev.product, ...data },
    }));
  }, []);

  const updatePayment = useCallback((data: Partial<PaymentStepData>) => {
    setProgress((prev) => ({
      ...prev,
      payment: { ...prev.payment, ...data },
    }));
  }, []);

  const updateStaff = useCallback((data: Partial<StaffStepData>) => {
    setProgress((prev) => ({
      ...prev,
      staff: { ...prev.staff, ...data },
    }));
  }, []);

  const markSkipped = useCallback((stepId: OnboardingStepId) => {
    setProgress((prev) => ({
      ...prev,
      skippedSteps: [...new Set([...prev.skippedSteps, stepId])],
    }));
  }, []);

  const clearProgress = useCallback(() => {
    if (typeof window !== "undefined") {
      localStorage.removeItem(ONBOARDING_STORAGE_KEY);
    }
    setProgress(createDefaultProgress());
  }, []);

  return {
    progress,
    isHydrated,
    isLoading,
    setCurrentStep,
    updateProfile,
    updateOutlet,
    updateProduct,
    updatePayment,
    updateStaff,
    markSkipped,
    clearProgress,
  };
}