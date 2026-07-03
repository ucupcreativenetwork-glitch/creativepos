import { createTransaction } from "@/lib/api/pos";
import {
  getOfflineDb,
  type OfflineQueueEntry,
  type OfflineQueueStatus,
} from "@/lib/offline/db";
import { isNetworkError } from "@/lib/offline/network";
import type {
  EnqueueOfflineTransactionInput,
  OfflineSyncResult,
} from "@/types/offline";
export async function enqueueTransaction(
  input: EnqueueOfflineTransactionInput
): Promise<OfflineQueueEntry> {
  const db = await getOfflineDb();
  const entry: OfflineQueueEntry = {
    id: input.idempotencyKey,
    idempotencyKey: input.idempotencyKey,
    payload: input.payload,
    receipt: input.receipt,
    status: "pending",
    createdAt: new Date().toISOString(),
  };

  await db.put("offlineQueue", entry);
  return entry;
}

export async function getQueueEntries(
  status?: OfflineQueueStatus
): Promise<OfflineQueueEntry[]> {
  const db = await getOfflineDb();
  const all = await db.getAll("offlineQueue");

  return all
    .filter((entry) => (status ? entry.status === status : true))
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt));
}

export async function getPendingCount(): Promise<number> {
  const pending = await getQueueEntries("pending");
  return pending.length;
}

export async function getFailedCount(): Promise<number> {
  const failed = await getQueueEntries("failed");
  return failed.length;
}

export async function removeFromQueue(id: string): Promise<void> {
  const db = await getOfflineDb();
  await db.delete("offlineQueue", id);
}

export async function markQueueEntryFailed(
  id: string,
  reason: string
): Promise<void> {
  const db = await getOfflineDb();
  const entry = await db.get("offlineQueue", id);

  if (!entry) return;

  entry.status = "failed";
  entry.failureReason = reason;
  await db.put("offlineQueue", entry);
}

export async function syncOfflineQueue(): Promise<OfflineSyncResult> {
  const pending = await getQueueEntries("pending");
  const result: OfflineSyncResult = {
    synced: 0,
    failed: 0,
    syncedReceipts: [],
    failedEntries: [],
  };

  for (const entry of pending) {
    try {
      const tx = await createTransaction(entry.payload, entry.idempotencyKey);
      await removeFromQueue(entry.id);
      result.synced += 1;
      result.syncedReceipts.push(tx);
    } catch (error) {
      if (isNetworkError(error)) {
        break;
      }

      const reason =
        error instanceof Error ? error.message : "Sinkronisasi gagal";
      await markQueueEntryFailed(entry.id, reason);
      result.failed += 1;
      result.failedEntries.push({ id: entry.id, reason });
    }
  }

  return result;
}