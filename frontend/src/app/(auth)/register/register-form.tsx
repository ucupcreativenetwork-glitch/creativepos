"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { useMutation } from "@tanstack/react-query";
import { Eye, EyeOff, UserPlus } from "lucide-react";
import { useMemo, useState } from "react";
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
import { register as registerApi } from "@/lib/api/auth";
import { getErrorMessage, getFieldErrors } from "@/lib/api/client";
import { formatCurrency } from "@/lib/utils/format";
import { useAuthStore } from "@/stores/auth-store";

const PACKAGE_OPTIONS = {
  starter: { name: "Starter", price: 99000 },
  business: { name: "Business", price: 299000 },
  enterprise: { name: "Enterprise", price: 799000 },
} as const;

type PackageSlug = keyof typeof PACKAGE_OPTIONS;

const registerSchema = z
  .object({
    business_name: z
      .string()
      .min(1, "Nama bisnis wajib diisi")
      .min(3, "Nama bisnis minimal 3 karakter"),
    owner_name: z
      .string()
      .min(1, "Nama pemilik wajib diisi")
      .min(2, "Nama pemilik minimal 2 karakter"),
    email: z
      .string()
      .min(1, "Email wajib diisi")
      .email("Format email tidak valid"),
    phone: z
      .string()
      .min(1, "Nomor telepon wajib diisi")
      .regex(/^08\d{8,12}$/, "Format nomor telepon tidak valid (08xxxxxxxxxx)"),
    password: z
      .string()
      .min(8, "Kata sandi minimal 8 karakter")
      .regex(
        /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
        "Kata sandi harus mengandung huruf besar, huruf kecil, dan angka"
      ),
    password_confirmation: z.string().min(1, "Konfirmasi kata sandi wajib diisi"),
  })
  .refine((data) => data.password === data.password_confirmation, {
    message: "Konfirmasi kata sandi tidak cocok",
    path: ["password_confirmation"],
  });

type RegisterForm = z.infer<typeof registerSchema>;

export function RegisterForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [showPassword, setShowPassword] = useState(false);
  const { setAuth } = useAuthStore();

  const packageSlug = useMemo(() => {
    const raw = searchParams.get("package")?.toLowerCase();
    if (raw && raw in PACKAGE_OPTIONS) {
      return raw as PackageSlug;
    }
    return "starter" as PackageSlug;
  }, [searchParams]);

  const selectedPackage = PACKAGE_OPTIONS[packageSlug];

  const {
    register,
    handleSubmit,
    setError,
    formState: { errors },
  } = useForm<RegisterForm>({
    resolver: zodResolver(registerSchema),
    defaultValues: {
      business_name: "",
      owner_name: "",
      email: "",
      phone: "",
      password: "",
      password_confirmation: "",
    },
  });

  const registerMutation = useMutation({
    mutationFn: registerApi,
    onSuccess: (data) => {
      setAuth({
        user: data.user,
        tenant: data.tenant,
        permissions: data.permissions,
        token: data.token,
      });
      toast.success("Pendaftaran berhasil! Selamat datang di CreativePOS.");
      router.push("/dashboard");
    },
    onError: (error) => {
      const fieldErrors = getFieldErrors(error);
      Object.entries(fieldErrors).forEach(([field, message]) => {
        setError(field as keyof RegisterForm, { message });
      });
      if (Object.keys(fieldErrors).length === 0) {
        toast.error(getErrorMessage(error));
      }
    },
  });

  const onSubmit = (data: RegisterForm) => {
    registerMutation.mutate({
      ...data,
      package_slug: packageSlug,
    });
  };

  return (
    <Card className="border-0 shadow-xl shadow-slate-200/60">
      <CardHeader className="space-y-1 text-center">
        <CardTitle className="text-2xl">Daftar</CardTitle>
        <CardDescription>
          Buat akun bisnis baru di CreativePOS
        </CardDescription>
        <div className="mx-auto mt-3 rounded-lg border border-primary/20 bg-primary/5 px-4 py-2 text-sm">
          <span className="text-muted-foreground">Paket dipilih: </span>
          <span className="font-semibold text-primary">{selectedPackage.name}</span>
          <span className="text-muted-foreground">
            {" "}
            ({formatCurrency(selectedPackage.price)}/bulan · trial 14 hari)
          </span>
        </div>
      </CardHeader>
      <form onSubmit={handleSubmit(onSubmit)}>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="business_name" required>
              Nama Bisnis
            </Label>
            <Input
              id="business_name"
              placeholder="Warung Makan Pak Budi"
              error={errors.business_name?.message}
              {...register("business_name")}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="owner_name" required>
              Nama Pemilik
            </Label>
            <Input
              id="owner_name"
              placeholder="Budi Santoso"
              error={errors.owner_name?.message}
              {...register("owner_name")}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="email" required>
              Email
            </Label>
            <Input
              id="email"
              type="email"
              placeholder="budi@warung.com"
              autoComplete="email"
              error={errors.email?.message}
              {...register("email")}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="phone" required>
              Nomor Telepon
            </Label>
            <Input
              id="phone"
              type="tel"
              placeholder="081234567890"
              autoComplete="tel"
              error={errors.phone?.message}
              {...register("phone")}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="password" required>
              Kata Sandi
            </Label>
            <div className="relative">
              <Input
                id="password"
                type={showPassword ? "text" : "password"}
                placeholder="Min. 8 karakter"
                autoComplete="new-password"
                error={errors.password?.message}
                className="pr-10"
                {...register("password")}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-2.5 text-muted-foreground hover:text-foreground"
                tabIndex={-1}
              >
                {showPassword ? (
                  <EyeOff className="h-4 w-4" />
                ) : (
                  <Eye className="h-4 w-4" />
                )}
              </button>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="password_confirmation" required>
              Konfirmasi Kata Sandi
            </Label>
            <Input
              id="password_confirmation"
              type="password"
              placeholder="Ulangi kata sandi"
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
            isLoading={registerMutation.isPending}
          >
            <UserPlus className="h-4 w-4" />
            Daftar Paket {selectedPackage.name}
          </Button>

          <p className="text-center text-xs text-muted-foreground">
            Ingin paket lain?{" "}
            <Link href="/#pricing" className="font-medium text-primary hover:underline">
              Lihat harga
            </Link>
          </p>

          <p className="text-center text-sm text-muted-foreground">
            Sudah punya akun?{" "}
            <Link
              href="/login"
              className="font-medium text-primary hover:underline"
            >
              Masuk di sini
            </Link>
          </p>
        </CardFooter>
      </form>
    </Card>
  );
}