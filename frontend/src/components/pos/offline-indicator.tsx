"use client";

import { CloudOff, RefreshCw, Wifi } from "lucide-react";
import { Button } from "@/components/ui/button";

interface OfflineIndicatorProps {
  isOnline: boolean;
  pendingCount: number;
  failedCount?: number;
  fromCache?: boolean;
  isSyncing?: boolean;
  onSync?: () => void;
  onRefreshCache?: () => void;
}

export function OfflineIndicator({
  isOnline,
  pendingCount,
  failedCount = 0,
  fromCache = false,
  isSyncing = false,
  onSync,
  onRefreshCache,
}: OfflineIndicatorProps) {
  return (
    <div className="flex items-center gap-2">
      <div
        className={`flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${
          isOnline
            ? "bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200"
            : "bg-red-50 text-red-700 ring-1 ring-red-200"
        }`}
        title={isOnline ? "Terhubung ke server" : "Mode offline — transaksi masuk antrian"}
      >
        <span
          className={`h-2 w-2 rounded-full ${
            isOnline ? "bg-emerald-500" : "bg-red-500 animate-pulse"
          }`}
        />
        {isOnline ? (
          <>
            <Wifi className="h-3 w-3" />
            Online
          </>
        ) : (
          <>
            <CloudOff className="h-3 w-3" />
            Offline
          </>
        )}
      </div>

      {fromCache && (
        <span className="hidden text-[10px] text-muted-foreground sm:inline">
          Katalog cache
        </span>
      )}

      {pendingCount > 0 && (
        <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-medium text-amber-800">
          {pendingCount} pending
        </span>
      )}

      {failedCount > 0 && (
        <span className="rounded-full bg-red-100 px-2 py-0.5 text-[10px] font-medium text-red-800">
          {failedCount} gagal
        </span>
      )}

      {isOnline && pendingCount > 0 && onSync && (
        <Button
          variant="ghost"
          size="sm"
          className="h-7 px-2 text-xs"
          onClick={onSync}
          disabled={isSyncing}
        >
          <RefreshCw className={`h-3 w-3 ${isSyncing ? "animate-spin" : ""}`} />
          Sync
        </Button>
      )}

      {onRefreshCache && (
        <Button
          variant="ghost"
          size="sm"
          className="h-7 px-2 text-xs"
          onClick={onRefreshCache}
          disabled={!isOnline}
          title="Refresh katalog produk"
        >
          <RefreshCw className="h-3 w-3" />
        </Button>
      )}
    </div>
  );
}