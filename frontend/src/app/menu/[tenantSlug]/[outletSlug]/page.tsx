"use client";

import { use } from "react";
import { useQuery } from "@tanstack/react-query";
import { QrMenuView } from "@/components/menu/qr-menu-view";
import { getPublicMenu } from "@/lib/api/public-menu";

export default function PublicMenuPage({
  params,
}: {
  params: Promise<{ tenantSlug: string; outletSlug: string }>;
}) {
  const { tenantSlug, outletSlug } = use(params);

  const { data: menu, isLoading, error } = useQuery({
    queryKey: ["public-menu", tenantSlug, outletSlug],
    queryFn: () => getPublicMenu(tenantSlug, outletSlug),
  });

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  if (error || !menu) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center p-6 text-center">
        <h1 className="text-lg font-semibold">Menu tidak ditemukan</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Pastikan link QR menu sudah benar.
        </p>
      </div>
    );
  }

  return (
    <QrMenuView
      menu={menu}
      tenantSlug={tenantSlug}
      outletSlug={outletSlug}
    />
  );
}