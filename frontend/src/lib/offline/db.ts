import { openDB, type DBSchema, type IDBPDatabase } from "idb";
import type { CreateTransactionPayload } from "@/types/pos";
import type { OfflineReceiptData } from "@/types/offline";

export type OfflineQueueStatus = "pending" | "failed";

export interface OfflineQueueEntry {
  id: string;
  idempotencyKey: string;
  payload: CreateTransactionPayload;
  receipt: OfflineReceiptData;
  status: OfflineQueueStatus;
  failureReason?: string;
  createdAt: string;
  syncedAt?: string;
  syncedTransactionNumber?: string;
}

export interface ProductCacheMeta {
  key: "meta";
  lastRefreshedAt: string;
  outletId?: number;
}

export interface ProductCacheBlob<T> {
  key: string;
  data: T;
  cachedAt: string;
}

interface CreativePosDB extends DBSchema {
  offlineQueue: {
    key: string;
    value: OfflineQueueEntry;
    indexes: { "by-status": OfflineQueueStatus; "by-created": string };
  };
  productCache: {
    key: string;
    value: ProductCacheBlob<unknown> | ProductCacheMeta;
  };
}

const DB_NAME = "creativepos-offline";
const DB_VERSION = 1;

let dbPromise: Promise<IDBPDatabase<CreativePosDB>> | null = null;

export function getOfflineDb() {
  if (!dbPromise) {
    dbPromise = openDB<CreativePosDB>(DB_NAME, DB_VERSION, {
      upgrade(db) {
        const queue = db.createObjectStore("offlineQueue", { keyPath: "id" });
        queue.createIndex("by-status", "status");
        queue.createIndex("by-created", "createdAt");
        db.createObjectStore("productCache", { keyPath: "key" });
      },
    });
  }

  return dbPromise;
}