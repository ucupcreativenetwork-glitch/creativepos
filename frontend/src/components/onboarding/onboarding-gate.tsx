"use client";

import { useQuery, useQueryClient } from "@tanstack/react-query";
import { getTenantSettings } from "@/lib/api/settings";
import { useAuthStore } from "@/stores/auth-store";
import { WizardModal } from "@/components/onboarding/wizard-modal";

export function OnboardingGate() {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);

  const { data: settings, isLoading } = useQuery({
    queryKey: ["settings", "tenant"],
    queryFn: getTenantSettings,
    staleTime: 30 * 1000,
    enabled: !!user && !user.is_super_admin,
  });

  const showWizard =
    !isLoading && !!settings && settings.setup_completed === false;

  const handleComplete = () => {
    queryClient.invalidateQueries({ queryKey: ["settings"] });
    queryClient.invalidateQueries({ queryKey: ["onboarding"] });
  };

  if (!user || user.is_super_admin) return null;

  return <WizardModal open={showWizard} onComplete={handleComplete} />;
}