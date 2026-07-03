"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { ArrowLeft, ShieldCheck } from "lucide-react";
import { useEffect } from "react";
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
import { login2fa } from "@/lib/api/auth";
import { getErrorMessage } from "@/lib/api/client";
import { getPostLoginPath } from "@/lib/auth/post-login-redirect";
import { useAuthStore } from "@/stores/auth-store";

const twoFactorSchema = z.object({
  code: z
    .string()
    .min(6, "Kode harus 6 digit")
    .max(6, "Kode harus 6 digit")
    .regex(/^\d{6}$/, "Kode harus berupa 6 angka"),
});

type TwoFactorForm = z.infer<typeof twoFactorSchema>;

export default function TwoFactorPage() {
  const router = useRouter();
  const { setAuth, requires2fa, pendingEmail } = useAuthStore();

  useEffect(() => {
    if (!requires2fa && !pendingEmail) {
      router.replace("/login");
    }
  }, [requires2fa, pendingEmail, router]);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<TwoFactorForm>({
    resolver: zodResolver(twoFactorSchema),
    defaultValues: { code: "" },
  });

  const twoFactorMutation = useMutation({
    mutationFn: login2fa,
    onSuccess: (data) => {
      setAuth({
        user: data.user,
        tenant: data.tenant,
        permissions: data.permissions,
        token: data.token,
      });
      toast.success("Verifikasi berhasil!");
      router.push(getPostLoginPath(data.user, data.permissions));
    },
    onError: (error) => {
      toast.error(getErrorMessage(error));
    },
  });

  const onSubmit = (data: TwoFactorForm) => {
    twoFactorMutation.mutate(data);
  };

  return (
    <Card className="border-0 shadow-xl shadow-slate-200/60">
      <CardHeader className="space-y-1 text-center">
        <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
          <ShieldCheck className="h-6 w-6 text-primary" />
        </div>
        <CardTitle className="text-2xl">Verifikasi 2FA</CardTitle>
        <CardDescription>
          Masukkan kode 6 digit dari aplikasi autentikasi Anda
          {pendingEmail && (
            <span className="mt-1 block text-xs">
              untuk akun <strong>{pendingEmail}</strong>
            </span>
          )}
        </CardDescription>
      </CardHeader>
      <form onSubmit={handleSubmit(onSubmit)}>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="code" required>
              Kode Verifikasi
            </Label>
            <Input
              id="code"
              type="text"
              inputMode="numeric"
              placeholder="123456"
              maxLength={6}
              autoComplete="one-time-code"
              className="text-center text-2xl tracking-[0.5em] font-mono"
              error={errors.code?.message}
              {...register("code")}
            />
          </div>
        </CardContent>

        <CardFooter className="flex flex-col gap-4">
          <Button
            type="submit"
            className="w-full"
            size="lg"
            isLoading={twoFactorMutation.isPending}
          >
            <ShieldCheck className="h-4 w-4" />
            Verifikasi
          </Button>

          <Link
            href="/login"
            className="inline-flex items-center justify-center gap-2 text-sm text-muted-foreground hover:text-primary transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Kembali ke halaman masuk
          </Link>
        </CardFooter>
      </form>
    </Card>
  );
}