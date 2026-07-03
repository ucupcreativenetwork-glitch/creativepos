"use client";

import { use } from "react";
import { useQuery } from "@tanstack/react-query";
import { QrMenuView } from "@/components/menu/qr-menu-view";
import { getTableMenu } from "@/lib/api/public-menu";

export default function TableMenuPage({
  params,
}: {
  params: Promise<{
    tenantSlug: string;
    outletSlug: string;
    token: string;
  }>;
}) {
  const { tenantSlug, outletSlug, token } = use(params);

  const { data: menu, isLoading, error } = useQuery({
    queryKey: ["table-menu", tenantSlug, outletSlug, token],
    queryFn: () => getTableMenu(tenantSlug, outletSlug, token),
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
        <h1 className="text-lg font-semibold">QR Meja tidak valid</h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Scan ulang kode QR di meja Anda.
        </p>
      </div>
    );
  }

  return (
    <QrMenuView
      menu={menu}
      tenantSlug={tenantSlug}
      outletSlug={outletSlug}
      tableToken={token}
    />
  );
}