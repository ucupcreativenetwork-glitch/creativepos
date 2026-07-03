"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Eye, EyeOff, KeyRound } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { changePassword } from "@/lib/api/auth";
import { getErrorMessage } from "@/lib/api/client";
import { useAuthStore } from "@/stores/auth-store";

const schema = z
  .object({
    current_password: z.string().min(1, "Kata sandi saat ini wajib diisi"),
    password: z
      .string()
      .min(8, "Minimal 8 karakter")
      .regex(/[A-Z]/, "Harus ada huruf besar")
      .regex(/[a-z]/, "Harus ada huruf kecil")
      .regex(/[0-9]/, "Harus ada angka"),
    password_confirmation: z.string().min(1, "Konfirmasi wajib diisi"),
  })
  .refine((data) => data.password === data.password_confirmation, {
    message: "Konfirmasi kata sandi tidak cocok",
    path: ["password_confirmation"],
  });

type ChangePasswordForm = z.infer<typeof schema>;

export default function ChangePasswordPage() {
  const router = useRouter();
  const { user, isAuthenticated, updateUser } = useAuthStore();
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);

  useEffect(() => {
    if (!isAuthenticated) {
      router.replace("/login");
    }
  }, [isAuthenticated, router]);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ChangePasswordForm>({
    resolver: zodResolver(schema),
  });

  const mutation = useMutation({
    mutationFn: changePassword,
    onSuccess: (updatedUser) => {
      updateUser(updatedUser);
      toast.success("Kata sandi berhasil diperbarui");
      router.replace("/dashboard");
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="mx-auto flex min-h-[70vh] max-w-lg items-center">
      <Card className="w-full">
        <CardHeader className="text-center">
          <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-amber-100 text-amber-700">
            <KeyRound className="h-6 w-6" />
          </div>
          <CardTitle>Ganti Kata Sandi</CardTitle>
          <CardDescription>
            {user?.must_change_password
              ? "Demi keamanan, ganti kata sandi default sebelum melanjutkan."
              : "Perbarui kata sandi akun Anda."}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form
            onSubmit={handleSubmit((values) => mutation.mutate(values))}
            className="space-y-4"
          >
            <div className="space-y-2">
              <Label htmlFor="current_password">Kata Sandi Saat Ini</Label>
              <div className="relative">
                <Input
                  id="current_password"
                  type={showCurrent ? "text" : "password"}
                  autoComplete="current-password"
                  error={errors.current_password?.message}
                  className="pr-10"
                  {...register("current_password")}
                />
                <button
                  type="button"
                  onClick={() => setShowCurrent((v) => !v)}
                  className="absolute right-3 top-2.5 text-muted-foreground"
                >
                  {showCurrent ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password">Kata Sandi Baru</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showNew ? "text" : "password"}
                  autoComplete="new-password"
                  error={errors.password?.message}
                  className="pr-10"
                  {...register("password")}
                />
                <button
                  type="button"
                  onClick={() => setShowNew((v) => !v)}
                  className="absolute right-3 top-2.5 text-muted-foreground"
                >
                  {showNew ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              </div>
              <p className="text-xs text-muted-foreground">
                Minimal 8 karakter, huruf besar, huruf kecil, dan angka.
              </p>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password_confirmation">Konfirmasi Kata Sandi Baru</Label>
              <Input
                id="password_confirmation"
                type="password"
                autoComplete="new-password"
                error={errors.password_confirmation?.message}
                {...register("password_confirmation")}
              />
            </div>

            <Button
              type="submit"
              className="w-full"
              isLoading={mutation.isPending}
            >
              Simpan Kata Sandi Baru
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}