"use client";

import Link from "next/link";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { ArrowLeft, Mail } from "lucide-react";
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
import { forgotPassword } from "@/lib/api/auth";
import { getErrorMessage } from "@/lib/api/client";

const forgotPasswordSchema = z.object({
  email: z
    .string()
    .min(1, "Email wajib diisi")
    .email("Format email tidak valid"),
});

type ForgotPasswordForm = z.infer<typeof forgotPasswordSchema>;

export default function ForgotPasswordPage() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<ForgotPasswordForm>({
    resolver: zodResolver(forgotPasswordSchema),
    defaultValues: { email: "" },
  });

  const forgotMutation = useMutation({
    mutationFn: forgotPassword,
    onSuccess: () => {
      toast.success(
        "Link reset kata sandi telah dikirim ke email Anda. Silakan periksa kotak masuk."
      );
    },
    onError: (error) => {
      toast.error(getErrorMessage(error));
    },
  });

  const onSubmit = (data: ForgotPasswordForm) => {
    forgotMutation.mutate(data);
  };

  return (
    <Card className="border-0 shadow-xl shadow-slate-200/60">
      <CardHeader className="space-y-1 text-center">
        <CardTitle className="text-2xl">Lupa Kata Sandi</CardTitle>
        <CardDescription>
          Masukkan email Anda dan kami akan mengirimkan link untuk reset kata
          sandi
        </CardDescription>
      </CardHeader>
      <form onSubmit={handleSubmit(onSubmit)}>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email" required>
              Email
            </Label>
            <Input
              id="email"
              type="email"
              placeholder="nama@bisnis.com"
              autoComplete="email"
              error={errors.email?.message}
              {...register("email")}
            />
          </div>
        </CardContent>

        <CardFooter className="flex flex-col gap-4">
          <Button
            type="submit"
            className="w-full"
            size="lg"
            isLoading={forgotMutation.isPending}
          >
            <Mail className="h-4 w-4" />
            Kirim Link Reset
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