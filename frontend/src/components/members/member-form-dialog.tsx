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
import { createMember, updateMember } from "@/lib/api/members";
import type { Member } from "@/types/loyalty";

const memberSchema = z.object({
  name: z.string().min(1, "Nama wajib diisi"),
  phone: z
    .string()
    .min(1, "Nomor telepon wajib diisi")
    .regex(/^08\d{8,12}$/, "Format: 08xxxxxxxxxx"),
  email: z.string().email("Email tidak valid").optional().or(z.literal("")),
  birthday: z.string().optional(),
  status: z.enum(["active", "inactive", "blocked"]).optional(),
});

type MemberForm = z.infer<typeof memberSchema>;

interface MemberFormDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  member?: Member | null;
}

export function MemberFormDialog({
  open,
  onClose,
  onSuccess,
  member,
}: MemberFormDialogProps) {
  const isEdit = Boolean(member);

  const {
    register,
    handleSubmit,
    reset,
    setError,
    formState: { errors },
  } = useForm<MemberForm>({
    resolver: zodResolver(memberSchema),
    defaultValues: { status: "active" },
  });

  useEffect(() => {
    if (!open) return;

    if (member) {
      reset({
        name: member.name,
        phone: member.phone,
        email: member.email ?? "",
        birthday: member.birthday ?? "",
        status: member.status,
      });
    } else {
      reset({ name: "", phone: "", email: "", birthday: "", status: "active" });
    }
  }, [open, member, reset]);

  const mutation = useMutation({
    mutationFn: (values: MemberForm) => {
      const payload = {
        ...values,
        email: values.email || undefined,
        birthday: values.birthday || undefined,
      };

      return isEdit && member
        ? updateMember(member.uuid, payload)
        : createMember(payload);
    },
    onSuccess: () => {
      toast.success(isEdit ? "Member diperbarui" : "Member ditambahkan");
      onSuccess();
      onClose();
    },
    onError: (error) => {
      const fieldErrors = getFieldErrors(error);
      Object.entries(fieldErrors).forEach(([field, message]) => {
        setError(field as keyof MemberForm, { message });
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
            {isEdit ? "Edit Member" : "Tambah Member"}
          </h2>
          <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
            <X className="h-5 w-5" />
          </button>
        </div>

        <form
          onSubmit={handleSubmit((v) => mutation.mutate(v))}
          className="space-y-4 p-6"
        >
          <div className="space-y-2">
            <Label htmlFor="name">Nama</Label>
            <Input id="name" {...register("name")} />
            {errors.name && <p className="text-xs text-red-600">{errors.name.message}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="phone">Telepon</Label>
            <Input id="phone" {...register("phone")} placeholder="08xxxxxxxxxx" />
            {errors.phone && <p className="text-xs text-red-600">{errors.phone.message}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" {...register("email")} />
            {errors.email && <p className="text-xs text-red-600">{errors.email.message}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="birthday">Tanggal Lahir</Label>
            <Input id="birthday" type="date" {...register("birthday")} />
          </div>

          {isEdit && (
            <div className="space-y-2">
              <Label htmlFor="status">Status</Label>
              <select
                id="status"
                {...register("status")}
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="active">Aktif</option>
                <option value="inactive">Nonaktif</option>
                <option value="blocked">Diblokir</option>
              </select>
            </div>
          )}

          <div className="flex justify-end gap-3">
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