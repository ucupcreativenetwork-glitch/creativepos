"use client";

import { useEffect } from "react";
import { useForm } from "react-hook-form";
import { useMutation } from "@tanstack/react-query";
import { X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import { createOutlet, updateOutlet } from "@/lib/api/settings";
import type { SettingsOutlet } from "@/types/settings";

interface OutletFormDialogProps {
  open: boolean;
  outlet?: SettingsOutlet | null;
  onClose: () => void;
  onSuccess: () => void;
}

interface OutletFormValues {
  name: string;
  code: string;
  address: string;
  phone: string;
  is_active: boolean;
  is_default: boolean;
}

export function OutletFormDialog({
  open,
  outlet,
  onClose,
  onSuccess,
}: OutletFormDialogProps) {
  const isEdit = Boolean(outlet);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<OutletFormValues>({
    defaultValues: {
      name: "",
      code: "",
      address: "",
      phone: "",
      is_active: true,
      is_default: false,
    },
  });

  useEffect(() => {
    if (!open) return;

    if (outlet) {
      reset({
        name: outlet.name,
        code: outlet.code,
        address: outlet.address ?? "",
        phone: outlet.phone ?? "",
        is_active: outlet.is_active,
        is_default: outlet.is_default,
      });
    } else {
      reset({
        name: "",
        code: "",
        address: "",
        phone: "",
        is_active: true,
        is_default: false,
      });
    }
  }, [open, outlet, reset]);

  const mutation = useMutation({
    mutationFn: (values: OutletFormValues) => {
      const payload = {
        name: values.name.trim(),
        code: values.code.trim().toUpperCase(),
        address: values.address.trim() || undefined,
        phone: values.phone.trim() || undefined,
        is_active: values.is_active,
        is_default: values.is_default,
      };

      return isEdit && outlet
        ? updateOutlet(outlet.uuid, payload)
        : createOutlet(payload);
    },
    onSuccess: () => {
      toast.success(isEdit ? "Outlet diperbarui" : "Outlet ditambahkan");
      onSuccess();
      onClose();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold">
            {isEdit ? "Edit Outlet" : "Tambah Outlet"}
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
            <Label htmlFor="outlet-name">Nama Outlet</Label>
            <Input id="outlet-name" {...register("name", { required: true })} />
            {errors.name && (
              <p className="text-xs text-red-600">Nama wajib diisi</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="outlet-code">Kode</Label>
            <Input id="outlet-code" {...register("code", { required: true })} placeholder="OUT01" />
            {errors.code && (
              <p className="text-xs text-red-600">Kode wajib diisi</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="outlet-address">Alamat</Label>
            <Input id="outlet-address" {...register("address")} />
          </div>

          <div className="space-y-2">
            <Label htmlFor="outlet-phone">Telepon</Label>
            <Input id="outlet-phone" {...register("phone")} />
          </div>

          <div className="flex flex-wrap gap-4 text-sm">
            <label className="flex items-center gap-2">
              <input type="checkbox" {...register("is_active")} />
              Aktif
            </label>
            <label className="flex items-center gap-2">
              <input type="checkbox" {...register("is_default")} />
              Outlet default
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