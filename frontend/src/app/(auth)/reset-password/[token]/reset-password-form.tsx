"use client";

import Link from "next/link";
import { useParams, useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { ArrowLeft, KeyRound } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { resetPassword } from "@/lib/api/auth";
import { getErrorMessage } from "@/lib/api/client";

const resetPasswordSchema = z
  .object({
    email: z
      .string()
      .min(1, "Email wajib diisi")
      .email("Format email tidak valid"),
    password: z
      .string()
      .min(8, "Kata sandi minimal 8 karakter")
      .regex(/[A-Z]/, "Harus mengandung huruf besar")
      .regex(/[a-z]/, "Harus mengandung huruf kecil")
      .regex(/[0-9]/, "Harus mengandung angka"),
    password_confirmation: z.string().min(1, "Konfirmasi kata sandi wajib diisi"),
  })
  .refine((data) => data.password === data.password_confirmation, {
    message: "Konfirmasi kata sandi tidak cocok",
    path: ["password_confirmation"],
  });

type ResetPasswordFormValues = z.infer<typeof resetPasswordSchema>;

export function ResetPasswordForm() {
  const router = useRouter();
  const params = useParams<{ token: string }>();
  const searchParams = useSearchParams();
  const token = params.token;
  const emailFromQuery = searchParams.get("email") ?? "";

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ResetPasswordFormValues>({
    resolver: zodResolver(resetPasswordSchema),
    defaultValues: {
      email: emailFromQuery,
      password: "",
      password_confirmation: "",
    },
  });

  const resetMutation = useMutation({
    mutationFn: (form: ResetPasswordFormValues) =>
      resetPassword({
        token,
        email: form.email,
        password: form.password,
        password_confirmation: form.password_confirmation,
      }),
    onSuccess: () => {
      toast.success("Kata sandi berhasil diubah. Silakan masuk.");
      router.push("/login");
    },
    onError: (error) => {
      toast.error(getErrorMessage(error));
    },
  });

  return (
    <Card className="border-0 shadow-xl shadow-slate-200/60">
      <CardHeader className="space-y-1 text-center">
        <CardTitle className="text-2xl">Reset Kata Sandi</CardTitle>
        <CardDescription>
          Masukkan kata sandi baru untuk akun Anda
        </CardDescription>
      </CardHeader>
      <form onSubmit={handleSubmit((v) => resetMutation.mutate(v))}>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email" required>
              Email
            </Label>
            <Input
              id="email"
              type="email"
              autoComplete="email"
              error={errors.email?.message}
              {...register("email")}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="password" required>
              Kata Sandi Baru
            </Label>
            <Input
              id="password"
              type="password"
              autoComplete="new-password"
              error={errors.password?.message}
              {...register("password")}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="password_confirmation" required>
              Konfirmasi Kata Sandi
            </Label>
            <Input
              id="password_confirmation"
              type="password"
              autoComplete="new-password"
              error={errors.password_confirmation?.message}
              {...register("password_confirmation")}
            />
          </div>
        </CardContent>

        <CardFooter className="flex flex-col gap-4">
          <Button
            type="submit"
            className="w-full"
            size="lg"
            isLoading={resetMutation.isPending}
          >
            <KeyRound className="h-4 w-4" />
            Simpan Kata Sandi Baru
          </Button>

          <Link
            href="/login"
            className="inline-flex items-center justify-center gap-2 text-sm text-muted-foreground transition-colors hover:text-primary"
          >
            <ArrowLeft className="h-4 w-4" />
            Kembali ke halaman masuk
          </Link>
        </CardFooter>
      </form>
    </Card>
  );
}