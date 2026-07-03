import {
  getPaymentMethods,
  getPosCategories,
  getPosProducts,
} from "@/lib/api/pos";
import { getOfflineDb } from "@/lib/offline/db";
import { isNetworkError } from "@/lib/offline/network";
import type { CachedPosCatalog } from "@/types/offline";
import type { PaymentMethod, PosCategory, PosProduct } from "@/types/pos";

const CACHE_KEYS = {
  products: "products",
  categories: "categories",
  paymentMethods: "paymentMethods",
  meta: "meta",
} as const;

const REFRESH_INTERVAL_MS = 15 * 60 * 1000;

async function readBlob<T>(key: string): Promise<T | null> {
  const db = await getOfflineDb();
  const record = await db.get("productCache", key);

  if (!record || record.key === CACHE_KEYS.meta) return null;

  return (record as { data: T }).data;
}

async function writeBlob<T>(key: string, data: T): Promise<void> {
  const db = await getOfflineDb();
  await db.put("productCache", {
    key,
    data,
    cachedAt: new Date().toISOString(),
  });
}

export async function getCachedCatalog(): Promise<CachedPosCatalog | null> {
  const [products, categories, paymentMethods, metaRecord] = await Promise.all([
    readBlob<PosProduct[]>(CACHE_KEYS.products),
    readBlob<PosCategory[]>(CACHE_KEYS.categories),
    readBlob<PaymentMethod[]>(CACHE_KEYS.paymentMethods),
    (async () => {
      const db = await getOfflineDb();
      const record = await db.get("productCache", CACHE_KEYS.meta);
      if (record?.key === CACHE_KEYS.meta) {
        return record as { lastRefreshedAt: string; outletId?: number };
      }
      return null;
    })(),
  ]);

  if (!products) return null;

  return {
    products,
    categories: categories ?? [],
    paymentMethods: paymentMethods ?? [],
    lastRefreshedAt: metaRecord?.lastRefreshedAt ?? new Date(0).toISOString(),
    outletId: metaRecord?.outletId,
  };
}

export async function saveProductCache(
  catalog: Omit<CachedPosCatalog, "lastRefreshedAt"> & {
    lastRefreshedAt?: string;
  }
): Promise<CachedPosCatalog> {
  const refreshedAt = catalog.lastRefreshedAt ?? new Date().toISOString();

  await Promise.all([
    writeBlob(CACHE_KEYS.products, catalog.products),
    writeBlob(CACHE_KEYS.categories, catalog.categories),
    writeBlob(CACHE_KEYS.paymentMethods, catalog.paymentMethods),
    (async () => {
      const db = await getOfflineDb();
      await db.put("productCache", {
        key: CACHE_KEYS.meta,
        lastRefreshedAt: refreshedAt,
        outletId: catalog.outletId,
      });
    })(),
  ]);

  return {
    ...catalog,
    lastRefreshedAt: refreshedAt,
  };
}

export async function refreshProductCacheFromApi(
  outletId?: number
): Promise<CachedPosCatalog> {
  const [products, categories, paymentMethods] = await Promise.all([
    getPosProducts(),
    getPosCategories(),
    getPaymentMethods(),
  ]);

  return saveProductCache({
    products,
    categories,
    paymentMethods,
    outletId,
  });
}

export function shouldRefreshCache(lastRefreshedAt: string): boolean {
  const last = new Date(lastRefreshedAt).getTime();
  if (Number.isNaN(last)) return true;
  return Date.now() - last >= REFRESH_INTERVAL_MS;
}

export function findProductByScanCode(
  products: PosProduct[],
  code: string
): PosProduct | undefined {
  const normalized = code.trim().toLowerCase();
  if (!normalized) return undefined;

  return products.find(
    (p) =>
      p.barcode?.toLowerCase() === normalized ||
      p.sku.toLowerCase() === normalized
  );
}

export function filterCachedProducts(
  products: PosProduct[],
  search?: string,
  categoryId?: number
): PosProduct[] {
  let filtered = products;

  if (categoryId) {
    filtered = filtered.filter((p) => p.category?.id === categoryId);
  }

  if (search?.trim()) {
    const q = search.trim().toLowerCase();
    filtered = filtered.filter(
      (p) =>
        p.name.toLowerCase().includes(q) ||
        p.sku.toLowerCase().includes(q) ||
        (p.barcode?.toLowerCase().includes(q) ?? false)
    );
  }

  return filtered;
}

export async function loadCatalogWithFallback(
  outletId?: number,
  options?: { force?: boolean }
): Promise<{
  catalog: CachedPosCatalog;
  fromCache: boolean;
}> {
  const cached = await getCachedCatalog();

  if (!navigator.onLine) {
    if (!cached) {
      throw new Error("Tidak ada data produk offline. Buka POS saat online terlebih dahulu.");
    }
    return { catalog: cached, fromCache: true };
  }

  const needsRefresh =
    options?.force ||
    !cached ||
    shouldRefreshCache(cached.lastRefreshedAt);

  if (!needsRefresh && cached) {
    return { catalog: cached, fromCache: true };
  }

  try {
    const fresh = await refreshProductCacheFromApi(outletId);
    return { catalog: fresh, fromCache: false };
  } catch (error) {
    if (cached && isNetworkError(error)) {
      return { catalog: cached, fromCache: true };
    }
    throw error;
  }
}

export { REFRESH_INTERVAL_MS };