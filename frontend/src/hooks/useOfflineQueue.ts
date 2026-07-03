"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { toast } from "sonner";
import {
  enqueueTransaction,
  getFailedCount,
  getPendingCount,
  getQueueEntries,
  syncOfflineQueue,
} from "@/lib/offline/transaction-queue";
import { useOnlineStatus } from "@/hooks/useOnlineStatus";
import type {
  EnqueueOfflineTransactionInput,
  OfflineSyncResult,
} from "@/types/offline";
import type { OfflineQueueEntry } from "@/lib/offline/db";

export function useOfflineQueue(options?: {
  autoSync?: boolean;
  onSynced?: (result: OfflineSyncResult) => void;
}) {
  const { isOnline } = useOnlineStatus();
  const [pendingCount, setPendingCount] = useState(0);
  const [failedCount, setFailedCount] = useState(0);
  const [failedEntries, setFailedEntries] = useState<OfflineQueueEntry[]>([]);
  const [isSyncing, setIsSyncing] = useState(false);
  const wasOfflineRef = useRef(false);

  const refreshCounts = useCallback(async () => {
    const [pending, failed, failedList] = await Promise.all([
      getPendingCount(),
      getFailedCount(),
      getQueueEntries("failed"),
    ]);
    setPendingCount(pending);
    setFailedCount(failed);
    setFailedEntries(failedList);
  }, []);

  const enqueue = useCallback(
    async (input: EnqueueOfflineTransactionInput) => {
      const entry = await enqueueTransaction(input);
      await refreshCounts();
      return entry;
    },
    [refreshCounts]
  );

  const syncNow = useCallback(async () => {
    if (!navigator.onLine || isSyncing) {
      return null;
    }

    const pending = await getPendingCount();
    if (pending === 0) return null;

    setIsSyncing(true);

    try {
      const result = await syncOfflineQueue();
      await refreshCounts();

      if (result.synced > 0) {
        toast.success(
          `${result.synced} transaksi offline berhasil disinkronkan`
        );
        options?.onSynced?.(result);
      }

      if (result.failed > 0) {
        toast.error(
          `${result.failed} transaksi gagal disinkronkan. Periksa antrian manual.`
        );
      }

      return result;
    } finally {
      setIsSyncing(false);
    }
  }, [isSyncing, refreshCounts, options]);

  useEffect(() => {
    refreshCounts();
  }, [refreshCounts]);

  useEffect(() => {
    if (!options?.autoSync) return;

    if (!isOnline) {
      wasOfflineRef.current = true;
      return;
    }

    if (wasOfflineRef.current || pendingCount > 0) {
      wasOfflineRef.current = false;
      void syncNow();
    }
  }, [isOnline, options?.autoSync, pendingCount, syncNow]);

  return {
    isOnline,
    pendingCount,
    failedCount,
    failedEntries,
    isSyncing,
    enqueue,
    syncNow,
    refreshCounts,
  };
}