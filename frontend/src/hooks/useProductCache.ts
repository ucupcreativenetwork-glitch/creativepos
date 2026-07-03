"use client";

import { useCallback, useEffect, useState } from "react";
import {
  filterCachedProducts,
  loadCatalogWithFallback,
  REFRESH_INTERVAL_MS,
} from "@/lib/offline/product-cache-store";
import { useOnlineStatus } from "@/hooks/useOnlineStatus";
import type { CachedPosCatalog } from "@/types/offline";
import type { PaymentMethod, PosCategory, PosProduct } from "@/types/pos";

interface UseProductCacheOptions {
  outletId?: number;
  search?: string;
  categoryId?: number;
  enabled?: boolean;
}

export function useProductCache({
  outletId,
  search,
  categoryId,
  enabled = true,
}: UseProductCacheOptions) {
  const { isOnline } = useOnlineStatus();
  const [catalog, setCatalog] = useState<CachedPosCatalog | null>(null);
  const [products, setProducts] = useState<PosProduct[]>([]);
  const [categories, setCategories] = useState<PosCategory[]>([]);
  const [paymentMethods, setPaymentMethods] = useState<PaymentMethod[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [fromCache, setFromCache] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const applyCatalog = useCallback(
    (data: CachedPosCatalog, cached: boolean) => {
      setCatalog(data);
      setProducts(filterCachedProducts(data.products, search, categoryId));
      setCategories(data.categories);
      setPaymentMethods(data.paymentMethods);
      setFromCache(cached);
    },
    [search, categoryId]
  );

  const load = useCallback(
    async (force = false) => {
      if (!enabled) return;

      setIsLoading(true);
      setError(null);

      try {
        const result = await loadCatalogWithFallback(outletId, { force });
        applyCatalog(result.catalog, result.fromCache);
      } catch (e) {
        const message =
          e instanceof Error ? e.message : "Gagal memuat katalog produk";
        setError(message);
      } finally {
        setIsLoading(false);
      }
    },
    [enabled, outletId, applyCatalog]
  );

  const refresh = useCallback(async () => {
    await load(true);
  }, [load]);

  useEffect(() => {
    void load(false);
  }, [load]);

  useEffect(() => {
    if (catalog) {
      setProducts(filterCachedProducts(catalog.products, search, categoryId));
    }
  }, [catalog, search, categoryId]);

  useEffect(() => {
    if (!enabled || !isOnline) return;

    const timer = window.setInterval(() => {
      void load(false);
    }, REFRESH_INTERVAL_MS);

    return () => window.clearInterval(timer);
  }, [enabled, isOnline, load]);

  return {
    products,
    categories,
    paymentMethods,
    catalog,
    isLoading,
    fromCache,
    isOnline,
    error,
    refresh,
    reload: load,
  };
}