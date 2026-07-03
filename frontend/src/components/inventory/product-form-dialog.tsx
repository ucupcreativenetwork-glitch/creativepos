"use client";

import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation, useQuery } from "@tanstack/react-query";
import { Upload, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage, getFieldErrors } from "@/lib/api/client";
import { createProduct, getProductCogs, updateProduct } from "@/lib/api/inventory";
import { uploadFile } from "@/lib/api/uploads";
import { formatCurrency } from "@/lib/utils/format";
import { resolveMediaUrl } from "@/lib/utils/media";
import type { Category, Product } from "@/types/inventory";

const productSchema = z.object({
  name: z.string().min(1, "Nama produk wajib diisi"),
  sku: z.string().min(1, "SKU wajib diisi"),
  barcode: z.string().optional(),
  category_id: z.string().optional(),
  base_price: z.string().min(1, "Harga wajib diisi"),
  cost_price: z.string().optional(),
  min_stock: z.string().optional(),
  track_stock: z.boolean().optional(),
  is_active: z.boolean().optional(),
  is_available: z.boolean().optional(),
  show_in_pos: z.boolean().optional(),
  initial_stock: z.string().optional(),
  image_url: z.string().optional(),
});

type ProductForm = z.infer<typeof productSchema>;

function parsePrice(value: string, field: string): number {
  const num = Number(value);
  if (!Number.isFinite(num) || num < 0) {
    throw new Error(`${field} tidak valid`);
  }
  return num;
}

function toProductPayload(values: ProductForm) {
  return {
    name: values.name,
    sku: values.sku,
    barcode: values.barcode || undefined,
    category_id: values.category_id ? Number(values.category_id) : null,
    base_price: parsePrice(values.base_price, "Harga jual"),
    cost_price: values.cost_price ? parsePrice(values.cost_price, "Harga modal") : 0,
    min_stock: values.min_stock ? Number(values.min_stock) : 0,
    track_stock: values.track_stock,
    is_active: values.is_active,
    is_available: values.is_available,
    show_in_pos: values.show_in_pos,
    initial_stock: values.initial_stock ? Number(values.initial_stock) : undefined,
    image_url: values.image_url || undefined,
  };
}

interface ProductFormDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  categories: Category[];
  product?: Product | null;
}

export function ProductFormDialog({
  open,
  onClose,
  onSuccess,
  categories,
  product,
}: ProductFormDialogProps) {
  const isEdit = Boolean(product);
  const [imageUploading, setImageUploading] = useState(false);

  const { data: cogsData } = useQuery({
    queryKey: ["inventory", "product-cogs", product?.uuid],
    queryFn: () => getProductCogs(product!.uuid),
    enabled: open && isEdit && !!product?.uuid,
    staleTime: 30 * 1000,
  });

  const {
    register,
    handleSubmit,
    reset,
    setError,
    watch,
    setValue,
    formState: { errors },
  } = useForm<ProductForm>({
    resolver: zodResolver(productSchema),
    defaultValues: {
      track_stock: true,
      is_active: true,
      is_available: true,
      show_in_pos: true,
      min_stock: "0",
      cost_price: "0",
      base_price: "0",
    },
  });

  useEffect(() => {
    if (!open) return;

    if (product) {
      reset({
        name: product.name,
        sku: product.sku,
        barcode: product.barcode ?? "",
        category_id: product.category?.id ? String(product.category.id) : "",
        base_price: String(product.base_price),
        cost_price: String(product.cost_price),
        min_stock: String(product.min_stock),
        track_stock: product.track_stock,
        is_active: product.is_active,
        is_available: product.is_available,
        show_in_pos: product.show_in_pos,
        image_url: product.image_url ?? "",
      });
    } else {
      reset({
        name: "",
        sku: "",
        barcode: "",
        category_id: "",
        base_price: "0",
        cost_price: "0",
        min_stock: "0",
        track_stock: true,
        is_active: true,
        is_available: true,
        show_in_pos: true,
        initial_stock: "0",
        image_url: "",
      });
    }
  }, [open, product, reset]);

  const handleImageUpload = async (file: File) => {
    if (!file.type.startsWith("image/")) {
      toast.error("File harus berupa gambar");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast.error("Ukuran gambar maksimal 5MB");
      return;
    }

    setImageUploading(true);
    try {
      const result = await uploadFile(file, "product");
      setValue("image_url", result.url);
      toast.success("Gambar produk berhasil diunggah");
    } catch (error) {
      toast.error(getErrorMessage(error));
    } finally {
      setImageUploading(false);
    }
  };

  const mutation = useMutation({
    mutationFn: (values: ProductForm) => {
      const payload = toProductPayload(values);

      return isEdit && product
        ? updateProduct(product.uuid, payload)
        : createProduct(payload);
    },
    onSuccess: () => {
      toast.success(isEdit ? "Produk berhasil diperbarui" : "Produk berhasil ditambahkan");
      onSuccess();
      onClose();
    },
    onError: (error) => {
      const fieldErrors = getFieldErrors(error);
      Object.entries(fieldErrors).forEach(([field, message]) => {
        setError(field as keyof ProductForm, { message });
      });
      toast.error(getErrorMessage(error));
    },
  });

  const imageUrl = watch("image_url");

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold">
            {isEdit ? "Edit Produk" : "Tambah Produk"}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1 text-muted-foreground hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form
          onSubmit={handleSubmit((values) => mutation.mutate(values))}
          className="space-y-4 p-6"
        >
          <div className="space-y-2">
            <Label htmlFor="name">Nama Produk</Label>
            <Input id="name" {...register("name")} />
            {errors.name && (
              <p className="text-xs text-red-600">{errors.name.message}</p>
            )}
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="sku">SKU</Label>
              <Input id="sku" {...register("sku")} />
              {errors.sku && (
                <p className="text-xs text-red-600">{errors.sku.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="barcode">Barcode</Label>
              <Input id="barcode" {...register("barcode")} />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Foto Produk</Label>
            <div className="flex items-center gap-4">
              {resolveMediaUrl(imageUrl) ? (
                <div className="h-16 w-16 overflow-hidden rounded-lg border border-border bg-slate-50">
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={resolveMediaUrl(imageUrl)}
                    alt="Produk"
                    className="h-full w-full object-cover"
                  />
                </div>
              ) : (
                <div className="flex h-16 w-16 items-center justify-center rounded-lg border border-dashed border-border bg-slate-50 text-xs text-muted-foreground">
                  Foto
                </div>
              )}
              <label className="cursor-pointer">
                <input
                  type="file"
                  accept="image/*"
                  className="hidden"
                  disabled={imageUploading}
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) void handleImageUpload(file);
                  }}
                />
                <span className="inline-flex h-9 items-center gap-2 rounded-lg border border-border bg-white px-3 text-sm hover:bg-slate-50">
                  <Upload className="h-4 w-4" />
                  {imageUploading ? "Mengunggah..." : "Unggah Gambar"}
                </span>
              </label>
            </div>
            <input type="hidden" {...register("image_url")} />
          </div>

          <div className="space-y-2">
            <Label htmlFor="category_id">Kategori</Label>
            <select
              id="category_id"
              {...register("category_id")}
              className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
            >
              <option value="">Tanpa kategori</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="base_price">Harga Jual</Label>
              <Input id="base_price" type="number" {...register("base_price")} />
              {errors.base_price && (
                <p className="text-xs text-red-600">{errors.base_price.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="cost_price">Harga Pokok (manual)</Label>
              <Input id="cost_price" type="number" {...register("cost_price")} />
            </div>
          </div>

          {isEdit && (cogsData?.cogs ?? 0) > 0 && (
            <div className="rounded-lg border border-blue-200 bg-blue-50 px-4 py-3">
              <p className="text-xs text-blue-700">HPP dari Resep (per unit)</p>
              <p className="text-lg font-semibold text-blue-900">
                {formatCurrency(cogsData?.cogs ?? 0)}
              </p>
            </div>
          )}

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="min_stock">Stok Minimum</Label>
              <Input id="min_stock" type="number" {...register("min_stock")} />
            </div>
            {!isEdit && (
              <div className="space-y-2">
                <Label htmlFor="initial_stock">Stok Awal</Label>
                <Input
                  id="initial_stock"
                  type="number"
                  {...register("initial_stock")}
                />
              </div>
            )}
          </div>

          <div className="flex flex-wrap gap-4 text-sm">
            <label className="flex items-center gap-2">
              <input type="checkbox" {...register("track_stock")} />
              Lacak stok
            </label>
            <label className="flex items-center gap-2">
              <input type="checkbox" {...register("is_active")} />
              Aktif
            </label>
            <label className="flex items-center gap-2">
              <input type="checkbox" {...register("show_in_pos")} />
              Tampil di POS
            </label>
          </div>

          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="outline" onClick={onClose}>
              Batal
            </Button>
            <Button type="submit" isLoading={mutation.isPending}>
              {isEdit ? "Simpan" : "Tambah"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}