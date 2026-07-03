"use client";

import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage, getFieldErrors } from "@/lib/api/client";
import {
  createRawMaterial,
  updateRawMaterial,
} from "@/lib/api/inventory";
import type { RawMaterial, RawMaterialUnit } from "@/types/inventory";

const UNITS: { value: RawMaterialUnit; label: string }[] = [
  { value: "gram", label: "Gram" },
  { value: "ml", label: "Mililiter (ml)" },
  { value: "pcs", label: "Pcs" },
  { value: "liter", label: "Liter" },
];

const schema = z.object({
  name: z.string().min(1, "Nama wajib diisi"),
  unit: z.enum(["gram", "ml", "pcs", "liter"]),
  current_stock: z.string().optional(),
  min_stock: z.string().optional(),
  cost_per_unit: z.string().optional(),
  is_active: z.boolean().optional(),
});

type FormValues = z.infer<typeof schema>;

interface RawMaterialFormDialogProps {
  open: boolean;
  material?: RawMaterial | null;
  onClose: () => void;
  onSuccess: () => void;
}

export function RawMaterialFormDialog({
  open,
  material,
  onClose,
  onSuccess,
}: RawMaterialFormDialogProps) {
  const isEdit = Boolean(material);

  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      unit: "gram",
      is_active: true,
    },
  });

  useEffect(() => {
    if (!open) return;

    if (material) {
      reset({
        name: material.name,
        unit: material.unit,
        current_stock: String(material.current_stock),
        min_stock: String(material.min_stock),
        cost_per_unit: String(material.cost_per_unit),
        is_active: material.is_active,
      });
    } else {
      reset({
        name: "",
        unit: "gram",
        current_stock: "0",
        min_stock: "0",
        cost_per_unit: "0",
        is_active: true,
      });
    }
  }, [open, material, reset]);

  const mutation = useMutation({
    mutationFn: (values: FormValues) => {
      const payload = {
        name: values.name,
        unit: values.unit,
        current_stock: values.current_stock ? Number(values.current_stock) : 0,
        min_stock: values.min_stock ? Number(values.min_stock) : 0,
        cost_per_unit: values.cost_per_unit ? Number(values.cost_per_unit) : 0,
        is_active: values.is_active,
      };

      return isEdit && material
        ? updateRawMaterial(material.id, payload)
        : createRawMaterial(payload);
    },
    onSuccess: () => {
      toast.success(isEdit ? "Bahan baku diperbarui" : "Bahan baku ditambahkan");
      onSuccess();
      onClose();
    },
    onError: (error) => {
      const fieldErrors = getFieldErrors(error);
      Object.entries(fieldErrors).forEach(([field, message]) => {
        setError(field as keyof FormValues, { message });
      });
      toast.error(getErrorMessage(error));
    },
  });

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold">
            {isEdit ? "Edit Bahan Baku" : "Tambah Bahan Baku"}
          </h2>
          <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form
          onSubmit={handleSubmit((values) => mutation.mutate(values))}
          className="space-y-4 p-6"
        >
          <div className="space-y-2">
            <Label>Nama Bahan</Label>
            <Input {...register("name")} placeholder="Espresso Beans" />
            {errors.name && (
              <p className="text-xs text-red-500">{errors.name.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label>Satuan</Label>
            <select
              {...register("unit")}
              className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
            >
              {UNITS.map((u) => (
                <option key={u.value} value={u.value}>{u.label}</option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label>Stok Saat Ini</Label>
              <Input type="number" step="0.001" {...register("current_stock")} />
            </div>
            <div className="space-y-2">
              <Label>Stok Minimum</Label>
              <Input type="number" step="0.001" {...register("min_stock")} />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Biaya per Satuan (HPP bahan)</Label>
            <Input type="number" step="0.0001" {...register("cost_per_unit")} />
          </div>

          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" {...register("is_active")} className="rounded" />
            Aktif
          </label>

          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="outline" onClick={onClose}>Batal</Button>
            <Button type="submit" isLoading={mutation.isPending}>
              {isEdit ? "Simpan" : "Tambah"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}