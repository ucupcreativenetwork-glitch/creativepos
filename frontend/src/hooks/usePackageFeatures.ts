"use client";

import { useQuery } from "@tanstack/react-query";
import { getSubscription } from "@/lib/api/billing";
import { getTenantSettings } from "@/lib/api/settings";

const TENANT_TOGGLE_MAP: Record<string, "feature_reservations" | "feature_delivery" | "feature_qr_menu"> = {
  reservation: "feature_reservations",
  delivery: "feature_delivery",
};

export function usePackageFeatures() {
  const { data: subscription, isLoading: subLoading } = useQuery({
    queryKey: ["billing", "subscription"],
    queryFn: getSubscription,
    staleTime: 5 * 60 * 1000,
  });

  const { data: tenantSettings, isLoading: settingsLoading } = useQuery({
    queryKey: ["settings", "tenant"],
    queryFn: getTenantSettings,
    staleTime: 5 * 60 * 1000,
  });

  const features = subscription?.package?.features ?? {};

  const hasPackageFeature = (key: string) => key in features;

  const hasFeature = (key: string) => {
    if (!hasPackageFeature(key)) return false;

    const toggleKey = TENANT_TOGGLE_MAP[key];
    if (toggleKey && tenantSettings) {
      return !!tenantSettings[toggleKey];
    }

    return true;
  };

  const getFeatureValue = (key: string) => features[key] as string | undefined;

  const hasFullReport =
    hasPackageFeature("report") && getFeatureValue("report") !== "basic";

  const hasWallet = hasPackageFeature("wallet");

  return {
    features,
    hasFeature,
    hasPackageFeature,
    getFeatureValue,
    hasFullReport,
    hasWallet,
    tenantSettings,
    isLoading: subLoading || settingsLoading,
    subscription,
  };
}