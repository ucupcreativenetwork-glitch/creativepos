"use client";

import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus, Save, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { getErrorMessage } from "@/lib/api/client";
import {
  getProducts,
  getProductRecipe,
  getRawMaterials,
  syncProductRecipe,
} from "@/lib/api/inventory";
import { formatCurrency } from "@/lib/utils/format";
import type { ProductRecipeIngredient, RawMaterialUnit } from "@/types/inventory";

interface DraftIngredient {
  key: string;
  id?: number;
  raw_material_id: number;
  quantity_needed: string;
  unit: RawMaterialUnit;
  notes: string;
}

function newDraft(): DraftIngredient {
  return {
    key: crypto.randomUUID(),
    raw_material_id: 0,
    quantity_needed: "",
    unit: "gram",
    notes: "",
  };
}

export function RecipeTab() {
  const queryClient = useQueryClient();
  const [productUuid, setProductUuid] = useState("");
  const [ingredients, setIngredients] = useState<DraftIngredient[]>([]);

  const { data: productsData } = useQuery({
    queryKey: ["inventory", "products", "recipe-select"],
    queryFn: () => getProducts({ per_page: 200 }),
    staleTime: 60 * 1000,
  });

  const { data: rawMaterialsData } = useQuery({
    queryKey: ["inventory", "raw-materials", "all"],
    queryFn: () => getRawMaterials({ per_page: 200, is_active: true }),
    staleTime: 60 * 1000,
  });

  const { data: recipeData, isLoading: recipeLoading } = useQuery({
    queryKey: ["inventory", "recipe", productUuid],
    queryFn: () => getProductRecipe(productUuid),
    enabled: !!productUuid,
    staleTime: 10 * 1000,
  });

  const products = productsData?.data ?? [];
  const rawMaterials = rawMaterialsData?.data ?? [];

  useEffect(() => {
    if (!recipeData) {
      setIngredients([]);
      return;
    }

    setIngredients(
      recipeData.ingredients.map((item) => ({
        key: String(item.id),
        id: item.id,
        raw_material_id: item.raw_material_id,
        quantity_needed: String(item.quantity_needed),
        unit: item.unit,
        notes: item.notes ?? "",
      }))
    );
  }, [recipeData]);

  const saveMutation = useMutation({
    mutationFn: () => {
      if (!productUuid) throw new Error("Pilih produk terlebih dahulu");

      const payload: ProductRecipeIngredient[] = ingredients
        .filter((i) => i.raw_material_id > 0 && Number(i.quantity_needed) > 0)
        .map((i) => ({
          id: i.id,
          raw_material_id: i.raw_material_id,
          quantity_needed: Number(i.quantity_needed),
          unit: i.unit,
          notes: i.notes || undefined,
        }));

      if (ingredients.length > 0 && payload.length === 0) {
        throw new Error(
          "Lengkapi bahan baku dan jumlah sebelum menyimpan resep."
        );
      }

      return syncProductRecipe(productUuid, payload);
    },
    onSuccess: (result) => {
      toast.success("Resep berhasil disimpan");
      queryClient.invalidateQueries({ queryKey: ["inventory", "recipe", productUuid] });
      queryClient.setQueryData(["inventory", "recipe", productUuid], result);
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const selectedProduct = products.find((p) => p.uuid === productUuid);
  const cogs = recipeData?.cogs ?? 0;

  const updateIngredient = (key: string, patch: Partial<DraftIngredient>) => {
    setIngredients((prev) =>
      prev.map((item) => (item.key === key ? { ...item, ...patch } : item))
    );
  };

  const handleMaterialChange = (key: string, materialId: number) => {
    const material = rawMaterials.find((m) => m.id === materialId);
    updateIngredient(key, {
      raw_material_id: materialId,
      unit: material?.unit ?? "gram",
    });
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Resep Produk (Bill of Materials)</CardTitle>
        <CardDescription>
          Tentukan komposisi bahan baku per produk jadi. Stok bahan otomatis berkurang saat terjual di POS.
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="grid gap-4 sm:grid-cols-2">
          <div className="space-y-2">
            <Label>Produk Jadi</Label>
            <select
              value={productUuid}
              onChange={(e) => setProductUuid(e.target.value)}
              className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
            >
              <option value="">Pilih produk...</option>
              {products.map((product) => (
                <option key={product.uuid} value={product.uuid}>
                  {product.name} ({product.sku})
                </option>
              ))}
            </select>
          </div>

          {selectedProduct && (
            <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-4 py-3">
              <p className="text-xs text-emerald-700">HPP per unit (dari resep)</p>
              <p className="text-xl font-bold text-emerald-800">
                {formatCurrency(cogs)}
              </p>
              <p className="text-xs text-emerald-600">
                Harga jual: {formatCurrency(selectedProduct.base_price)}
                {cogs > 0 && selectedProduct.base_price > cogs && (
                  <> · Margin: {formatCurrency(selectedProduct.base_price - cogs)}</>
                )}
              </p>
            </div>
          )}
        </div>

        {!productUuid ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            Pilih produk untuk mengatur resep
          </p>
        ) : recipeLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="h-14 animate-pulse rounded-lg bg-slate-100" />
            ))}
          </div>
        ) : (
          <>
            <div className="space-y-3">
              {ingredients.length === 0 && (
                <p className="text-sm text-muted-foreground">
                  Belum ada bahan dalam resep. Tambahkan bahan baku di bawah.
                </p>
              )}

              {ingredients.map((item) => (
                <div
                  key={item.key}
                  className="grid gap-3 rounded-lg border border-border p-4 sm:grid-cols-12"
                >
                  <div className="sm:col-span-4 space-y-1">
                    <Label className="text-xs">Bahan Baku</Label>
                    <select
                      value={item.raw_material_id || ""}
                      onChange={(e) =>
                        handleMaterialChange(item.key, Number(e.target.value))
                      }
                      className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
                    >
                      <option value="">Pilih bahan...</option>
                      {rawMaterials.map((m) => (
                        <option key={m.id} value={m.id}>
                          {m.name} ({m.unit})
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="sm:col-span-2 space-y-1">
                    <Label className="text-xs">Jumlah</Label>
                    <Input
                      type="number"
                      step="0.001"
                      value={item.quantity_needed}
                      onChange={(e) =>
                        updateIngredient(item.key, { quantity_needed: e.target.value })
                      }
                      placeholder="20"
                    />
                  </div>
                  <div className="sm:col-span-2 space-y-1">
                    <Label className="text-xs">Satuan</Label>
                    <Input value={item.unit} readOnly className="bg-slate-50" />
                  </div>
                  <div className="sm:col-span-3 space-y-1">
                    <Label className="text-xs">Catatan</Label>
                    <Input
                      value={item.notes}
                      onChange={(e) =>
                        updateIngredient(item.key, { notes: e.target.value })
                      }
                      placeholder="Opsional"
                    />
                  </div>
                  <div className="flex items-end sm:col-span-1">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() =>
                        setIngredients((prev) =>
                          prev.filter((i) => i.key !== item.key)
                        )
                      }
                    >
                      <Trash2 className="h-4 w-4 text-red-500" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex flex-wrap gap-2">
              <Button
                variant="outline"
                onClick={() => setIngredients((prev) => [...prev, newDraft()])}
              >
                <Plus className="h-4 w-4" />
                Tambah Bahan
              </Button>
              <Button
                onClick={() => saveMutation.mutate()}
                isLoading={saveMutation.isPending}
              >
                <Save className="h-4 w-4" />
                Simpan Resep
              </Button>
            </div>
          </>
        )}
      </CardContent>
    </Card>
  );
}