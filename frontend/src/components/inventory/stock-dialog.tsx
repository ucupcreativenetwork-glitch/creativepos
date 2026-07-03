"use client";

import { useEffect, useMemo } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import {
  stockAdjustment,
  stockIn,
  stockOut,
} from "@/lib/api/inventory";
import type { Product, Warehouse } from "@/types/inventory";

const stockSchema = z.object({
  warehouse_id: z.string().min(1, "Gudang wajib dipilih"),
  quantity: z.string().min(1, "Jumlah wajib diisi"),
  notes: z.string().optional(),
});

type StockForm = z.infer<typeof stockSchema>;

export type StockAction = "in" | "out" | "adjustment";

interface StockDialogProps {
  open: boolean;
  action: StockAction;
  product: Product | null;
  warehouses: Warehouse[];
  onClose: () => void;
  onSuccess: () => void;
}

const actionLabels: Record<StockAction, string> = {
  in: "Tambah Stok",
  out: "Kurang Stok",
  adjustment: "Sesuaikan Stok",
};

function warehouseStock(product: Product, warehouseId: number): number {
  const row = product.stocks?.find((stock) => stock.warehouse_id === warehouseId);
  return row?.quantity ?? 0;
}

export function StockDialog({
  open,
  action,
  product,
  warehouses,
  onClose,
  onSuccess,
}: StockDialogProps) {
  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors },
  } = useForm<StockForm>({
    resolver: zodResolver(stockSchema),
  });

  const selectedWarehouseId = Number(watch("warehouse_id") || 0);

  const currentWarehouseStock = useMemo(() => {
    if (!product || !selectedWarehouseId) return 0;
    return warehouseStock(product, selectedWarehouseId);
  }, [product, selectedWarehouseId]);

  useEffect(() => {
    if (open && product) {
      const defaultWarehouseId = warehouses[0]?.id
        ?? product.stocks?.[0]?.warehouse_id
        ?? null;

      reset({
        warehouse_id: defaultWarehouseId ? String(defaultWarehouseId) : "",
        quantity:
          action === "adjustment"
            ? String(
                defaultWarehouseId
                  ? warehouseStock(product, defaultWarehouseId)
                  : product.total_stock
              )
            : "1",
        notes: "",
      });
    }
  }, [open, product, warehouses, action, reset]);

  const mutation = useMutation({
    mutationFn: async (values: StockForm) => {
      if (!product) return;

      const quantity = Number(values.quantity);
      if (!Number.isFinite(quantity)) {
        throw new Error("Jumlah tidak valid");
      }

      if (action === "adjustment") {
        if (quantity < 0) {
          throw new Error("Stok baru tidak boleh negatif");
        }
      } else if (quantity <= 0) {
        throw new Error("Jumlah harus lebih dari 0");
      }

      if (action === "out") {
        const available = warehouseStock(product, Number(values.warehouse_id));
        if (quantity > available) {
          throw new Error(`Stok tidak mencukupi (tersedia: ${available})`);
        }
      }

      const payload = {
        product_id: product.id,
        warehouse_id: Number(values.warehouse_id),
        quantity,
        notes: values.notes?.trim() || undefined,
      };

      if (action === "in") await stockIn(payload);
      else if (action === "out") await stockOut(payload);
      else await stockAdjustment(payload);
    },
    onSuccess: () => {
      toast.success(`${actionLabels[action]} berhasil`);
      onSuccess();
      onClose();
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  if (!open || !product) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">{actionLabels[action]}</h2>
            <p className="text-sm text-muted-foreground">{product.name}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1 text-muted-foreground hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {warehouses.length === 0 ? (
          <div className="space-y-4 p-6">
            <p className="text-sm text-muted-foreground">
              Belum ada gudang aktif. Tambahkan outlet/gudang di pengaturan terlebih dahulu.
            </p>
            <div className="flex justify-end">
              <Button type="button" variant="outline" onClick={onClose}>
                Tutup
              </Button>
            </div>
          </div>
        ) : (
          <form
            onSubmit={handleSubmit((values) => mutation.mutate(values))}
            className="space-y-4 p-6"
          >
            <div className="space-y-2">
              <Label htmlFor="warehouse_id">Gudang</Label>
              <select
                id="warehouse_id"
                {...register("warehouse_id")}
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                {warehouses.map((wh) => (
                  <option key={wh.id} value={wh.id}>
                    {wh.name} ({wh.code})
                  </option>
                ))}
              </select>
              {errors.warehouse_id && (
                <p className="text-xs text-red-600">{errors.warehouse_id.message}</p>
              )}
              <p className="text-xs text-muted-foreground">
                Stok di gudang ini: {currentWarehouseStock}
                {action !== "adjustment" && (
                  <> · Total semua gudang: {product.total_stock}</>
                )}
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="quantity">
                {action === "adjustment" ? "Jumlah Stok Baru" : "Jumlah"}
              </Label>
              <Input
                id="quantity"
                type="number"
                step={action === "adjustment" ? "1" : "0.001"}
                min={action === "adjustment" ? "0" : "0.001"}
                {...register("quantity")}
              />
              {errors.quantity && (
                <p className="text-xs text-red-600">{errors.quantity.message}</p>
              )}
              {action === "out" && currentWarehouseStock > 0 && (
                <p className="text-xs text-muted-foreground">
                  Maksimum bisa dikurangi: {currentWarehouseStock}
                </p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="notes">Catatan</Label>
              <Input id="notes" {...register("notes")} placeholder="Opsional" />
            </div>

            <div className="flex justify-end gap-3">
              <Button type="button" variant="outline" onClick={onClose}>
                Batal
              </Button>
              <Button type="submit" isLoading={mutation.isPending}>
                Simpan
              </Button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}