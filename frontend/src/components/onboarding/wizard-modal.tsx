"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  Building2,
  Check,
  ChevronLeft,
  ChevronRight,
  CreditCard,
  Package,
  PartyPopper,
  Sparkles,
  Store,
  Upload,
  UserPlus,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { inviteUser } from "@/lib/api/auth";
import { getErrorMessage } from "@/lib/api/client";
import { uploadFile } from "@/lib/api/uploads";
import { createCategory, createProduct } from "@/lib/api/inventory";
import {
  completeSetup,
  createOutlet,
  getSettingsOutlets,
  getTenantSettings,
  syncPaymentMethods,
  updateOnboardingProgress,
  updateOutlet as updateOutletApi,
  updateTenantSettings,
} from "@/lib/api/settings";
import { useOnboardingWizard } from "@/hooks/useOnboardingWizard";
import { cn } from "@/lib/utils/cn";
import {
  BUSINESS_TYPE_OPTIONS,
  ONBOARDING_STEPS,
  PAYMENT_METHOD_OPTIONS,
  TIMEZONE_OPTIONS,
  type OnboardingStepId,
} from "@/types/onboarding";

interface WizardModalProps {
  open: boolean;
  onComplete: () => void;
}

const STEP_ICONS = [Building2, Store, Package, CreditCard, UserPlus];

function sanitizeLogoUrl(url: string): string {
  if (!url || url.startsWith("data:")) return "";
  return url;
}

function generateSku(name: string): string {
  const slug = name
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, "")
    .slice(0, 6);
  const suffix = Date.now().toString(36).toUpperCase().slice(-4);
  return `PRD-${slug || "ITEM"}-${suffix}`;
}

export function WizardModal({ open, onComplete }: WizardModalProps) {
  const {
    progress,
    isHydrated,
    isLoading,
    setCurrentStep,
    updateProfile,
    updateOutlet,
    updateProduct,
    updatePayment,
    updateStaff,
    markSkipped,
    clearProgress,
  } = useOnboardingWizard(open);

  const [submitting, setSubmitting] = useState(false);
  const [showWelcome, setShowWelcome] = useState(false);
  const [logoPreview, setLogoPreview] = useState<string | null>(null);
  const [logoUploading, setLogoUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const confettiRef = useRef<typeof import("canvas-confetti") | null>(null);

  const currentStep = progress.currentStep;
  const stepIndex = currentStep - 1;
  const isSkippable = currentStep >= 3;

  useEffect(() => {
    if (!open || !isHydrated) return;

    async function preload() {
      try {
        const [settings, outlets] = await Promise.all([
          getTenantSettings(),
          getSettingsOutlets(),
        ]);

        updateProfile({
          business_name: settings.business_name ?? "",
          business_type: (settings.business_type as typeof progress.profile.business_type) ?? "",
          logo_url: settings.logo_url ?? "",
          address: settings.address ?? "",
          phone: settings.phone ?? "",
        });

        if (settings.logo_url) {
          setLogoPreview(settings.logo_url);
        }

        const defaultOutlet =
          outlets.find((o) => o.is_default) ?? outlets[0] ?? null;

        if (defaultOutlet) {
          updateOutlet({
            outlet_id: defaultOutlet.id,
            outlet_uuid: defaultOutlet.uuid,
            name: defaultOutlet.name,
            code: defaultOutlet.code,
            timezone: settings.timezone ?? "Asia/Jakarta",
            feature_reservations: settings.feature_reservations ?? true,
            feature_delivery: settings.feature_delivery ?? true,
            feature_qr_menu: settings.feature_qr_menu ?? true,
          });
        } else {
          updateOutlet({
            timezone: settings.timezone ?? "Asia/Jakarta",
            feature_reservations: settings.feature_reservations ?? true,
            feature_delivery: settings.feature_delivery ?? true,
            feature_qr_menu: settings.feature_qr_menu ?? true,
          });
        }

        if (settings.enabled_payment_methods?.length) {
          updatePayment({ selected: settings.enabled_payment_methods });
        }
      } catch {
        // Form tetap bisa diisi manual
      }
    }

    preload();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, isHydrated]);

  const profileValid = useMemo(
    () =>
      progress.profile.business_name.trim().length >= 2 &&
      progress.profile.business_type !== "" &&
      progress.profile.address.trim().length >= 5 &&
      progress.profile.phone.trim().length >= 8,
    [progress.profile],
  );

  const outletValid = useMemo(
    () =>
      progress.outlet.name.trim().length >= 2 &&
      progress.outlet.code.trim().length >= 2 &&
      progress.outlet.timezone !== "",
    [progress.outlet],
  );

  const productValid = useMemo(
    () =>
      progress.product.name.trim().length >= 2 &&
      progress.product.category_name.trim().length >= 2 &&
      Number(progress.product.base_price) > 0,
    [progress.product],
  );

  const paymentValid = useMemo(
    () => progress.payment.selected.length > 0,
    [progress.payment],
  );

  const staffValid = useMemo(() => {
    const email = progress.staff.email.trim();
    if (!email) return false;
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
  }, [progress.staff.email]);

  const canProceed = useMemo(() => {
    switch (currentStep) {
      case 1:
        return profileValid;
      case 2:
        return outletValid;
      case 3:
        return productValid;
      case 4:
        return paymentValid;
      case 5:
        return staffValid;
      default:
        return false;
    }
  }, [
    currentStep,
    profileValid,
    outletValid,
    productValid,
    paymentValid,
    staffValid,
  ]);

  const fireConfetti = useCallback(async () => {
    if (!confettiRef.current) {
      confettiRef.current = (await import("canvas-confetti")).default;
    }
    const confetti = confettiRef.current;
    const duration = 2500;
    const end = Date.now() + duration;

    const frame = () => {
      confetti({
        particleCount: 4,
        angle: 60,
        spread: 55,
        origin: { x: 0, y: 0.7 },
        colors: ["#2563eb", "#10b981", "#f59e0b", "#ec4899"],
      });
      confetti({
        particleCount: 4,
        angle: 120,
        spread: 55,
        origin: { x: 1, y: 0.7 },
        colors: ["#2563eb", "#10b981", "#f59e0b", "#ec4899"],
      });
      if (Date.now() < end) {
        requestAnimationFrame(frame);
      }
    };

    frame();
  }, []);

  const finishWizard = useCallback(async () => {
    await completeSetup();
    clearProgress();
    setShowWelcome(true);
    await fireConfetti();
    setTimeout(() => {
      setShowWelcome(false);
      onComplete();
    }, 3200);
  }, [clearProgress, fireConfetti, onComplete]);

  const handleLogoChange = async (file: File | null) => {
    if (!file) return;
    if (!file.type.startsWith("image/")) {
      toast.error("File harus berupa gambar");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast.error("Ukuran logo maksimal 5MB");
      return;
    }

    const previewUrl = URL.createObjectURL(file);
    setLogoPreview(previewUrl);
    setLogoUploading(true);

    try {
      const result = await uploadFile(file, "logo");
      updateProfile({ logo_url: result.url });
      setLogoPreview(result.url);
      toast.success("Logo berhasil diunggah");
    } catch (error) {
      setLogoPreview(null);
      updateProfile({ logo_url: "" });
      toast.error(getErrorMessage(error));
    } finally {
      setLogoUploading(false);
      URL.revokeObjectURL(previewUrl);
    }
  };

  const saveProfileStep = async () => {
    const logoUrl = sanitizeLogoUrl(progress.profile.logo_url);

    await updateTenantSettings({
      business_name: progress.profile.business_name.trim(),
      business_type: progress.profile.business_type,
      logo_url: logoUrl || undefined,
      address: progress.profile.address.trim(),
      phone: progress.profile.phone.trim(),
    });
    await updateOnboardingProgress({
      current_step: 2,
      completed_steps: ["profile"],
    });
  };

  const saveOutletStep = async () => {
    const payload = {
      name: progress.outlet.name.trim(),
      code: progress.outlet.code.trim().toUpperCase(),
      is_active: true,
      is_default: true,
    };

    if (progress.outlet.outlet_uuid) {
      await updateOutletApi(progress.outlet.outlet_uuid, payload);
    } else {
      const created = await createOutlet(payload);
      updateOutlet({
        outlet_id: created.id,
        outlet_uuid: created.uuid,
      });
    }

    await updateTenantSettings({
      timezone: progress.outlet.timezone,
      feature_reservations: progress.outlet.feature_reservations,
      feature_delivery: progress.outlet.feature_delivery,
      feature_qr_menu: progress.outlet.feature_qr_menu,
    });

    await updateOnboardingProgress({
      current_step: 3,
      completed_steps: ["profile", "outlet"],
    });
  };

  const saveProductStep = async () => {
    const category = await createCategory({
      name: progress.product.category_name.trim(),
      is_active: true,
    });

    await createProduct({
      name: progress.product.name.trim(),
      sku: generateSku(progress.product.name),
      category_id: category.id,
      base_price: Number(progress.product.base_price),
      cost_price: 0,
      is_active: true,
      is_available: true,
      show_in_pos: true,
      track_stock: false,
      initial_stock: 0,
    });

    await updateOnboardingProgress({
      current_step: 4,
      completed_steps: ["profile", "outlet", "product"],
    });
  };

  const savePaymentStep = async () => {
    await syncPaymentMethods(progress.payment.selected);
    await updateOnboardingProgress({
      current_step: 5,
      completed_steps: ["profile", "outlet", "product", "payment"],
    });
  };

  const saveStaffStep = async () => {
    const result = await inviteUser({
      email: progress.staff.email.trim(),
      name: progress.staff.name.trim() || undefined,
      role: progress.staff.role,
    });
    toast.success(result.message);
    await updateOnboardingProgress({
      current_step: 5,
      completed_steps: ["profile", "outlet", "product", "payment", "staff"],
      staff_invited: true,
    });
  };

  const handleNext = async () => {
    if (currentStep === 1 && logoUploading) {
      toast.error("Tunggu upload logo selesai");
      return;
    }

    setSubmitting(true);
    try {
      if (currentStep === 1) await saveProfileStep();
      else if (currentStep === 2) await saveOutletStep();
      else if (currentStep === 3) await saveProductStep();
      else if (currentStep === 4) await savePaymentStep();
      else if (currentStep === 5) {
        await saveStaffStep();
        await finishWizard();
        return;
      }

      setCurrentStep(currentStep + 1);
    } catch (error) {
      toast.error(getErrorMessage(error));
    } finally {
      setSubmitting(false);
    }
  };

  const handleSkip = async () => {
    const stepMap: Record<number, OnboardingStepId> = {
      3: "product",
      4: "payment",
      5: "staff",
    };
    const stepId = stepMap[currentStep];
    if (!stepId) return;

    setSubmitting(true);
    try {
      markSkipped(stepId);
      await updateOnboardingProgress({
        current_step: Math.min(currentStep + 1, 5),
        skipped_steps: [...new Set([...progress.skippedSteps, stepId])],
      });

      if (currentStep === 5) {
        await finishWizard();
        return;
      }

      setCurrentStep(currentStep + 1);
    } catch (error) {
      toast.error(getErrorMessage(error));
    } finally {
      setSubmitting(false);
    }
  };

  const togglePayment = (code: string) => {
    const selected = progress.payment.selected.includes(code)
      ? progress.payment.selected.filter((c) => c !== code)
      : [...progress.payment.selected, code];
    updatePayment({ selected });
  };

  if (!open) return null;

  if (isLoading || !isHydrated) {
    return (
      <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/80 backdrop-blur-sm">
        <div className="flex flex-col items-center gap-3 text-white">
          <span className="h-10 w-10 animate-spin rounded-full border-4 border-white/30 border-t-white" />
          <p className="text-sm">Memuat wizard setup...</p>
        </div>
      </div>
    );
  }

  if (showWelcome) {
    return (
      <div className="fixed inset-0 z-[100] flex items-center justify-center bg-gradient-to-br from-primary/90 via-blue-700 to-indigo-900">
        <div className="animate-in fade-in zoom-in text-center text-white duration-500">
          <PartyPopper className="mx-auto mb-4 h-16 w-16" />
          <h1 className="text-3xl font-bold">Selamat Datang!</h1>
          <p className="mt-2 text-lg text-blue-100">
            CreativePOS siap digunakan. Mari mulai berjualan!
          </p>
          <Sparkles className="mx-auto mt-6 h-8 w-8 animate-pulse" />
        </div>
      </div>
    );
  }

  const StepIcon = STEP_ICONS[stepIndex] ?? Building2;

  return (
    <div
      className="fixed inset-0 z-[100] flex flex-col bg-slate-50"
      role="dialog"
      aria-modal="true"
      aria-labelledby="onboarding-wizard-title"
    >
      <header className="border-b border-border bg-white px-6 py-5 shadow-sm">
        <div className="mx-auto max-w-3xl">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <p className="text-xs font-medium uppercase tracking-wider text-primary">
                Setup Awal
              </p>
              <h1
                id="onboarding-wizard-title"
                className="text-xl font-bold text-foreground"
              >
                Selamat datang di CreativePOS
              </h1>
            </div>
            <span className="rounded-full bg-primary/10 px-3 py-1 text-sm font-medium text-primary">
              Langkah {currentStep} / 5
            </span>
          </div>

          <div className="flex gap-2">
            {ONBOARDING_STEPS.map((step, index) => {
              const done = index + 1 < currentStep;
              const active = index + 1 === currentStep;
              return (
                <div key={step.id} className="flex-1">
                  <div
                    className={cn(
                      "h-2 rounded-full transition-all duration-300",
                      done && "bg-primary",
                      active && "bg-primary/60",
                      !done && !active && "bg-slate-200",
                    )}
                  />
                  <p
                    className={cn(
                      "mt-1.5 hidden truncate text-[10px] font-medium sm:block",
                      active ? "text-primary" : "text-muted-foreground",
                    )}
                  >
                    {step.label}
                  </p>
                </div>
              );
            })}
          </div>
        </div>
      </header>

      <main className="flex-1 overflow-y-auto px-6 py-8">
        <div className="mx-auto max-w-3xl">
          <div className="mb-6 flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10 text-primary">
              <StepIcon className="h-6 w-6" />
            </div>
            <div>
              <h2 className="text-lg font-semibold">
                {ONBOARDING_STEPS[stepIndex]?.label}
              </h2>
              <p className="text-sm text-muted-foreground">
                {currentStep === 1 &&
                  "Lengkapi profil bisnis agar struk dan laporan tampil benar."}
                {currentStep === 2 &&
                  "Atur outlet pertama dan fitur yang ingin diaktifkan."}
                {currentStep === 3 &&
                  "Tambahkan produk pertama atau lewati dan isi nanti."}
                {currentStep === 4 &&
                  "Pilih metode pembayaran yang tersedia di kasir."}
                {currentStep === 5 &&
                  "Undang kasir atau manager (opsional)."}
              </p>
            </div>
          </div>

          {currentStep === 1 && (
            <div className="space-y-5 rounded-xl border border-border bg-white p-6 shadow-sm">
              <div className="space-y-2">
                <Label htmlFor="business_name">Nama Toko *</Label>
                <Input
                  id="business_name"
                  value={progress.profile.business_name}
                  onChange={(e) =>
                    updateProfile({ business_name: e.target.value })
                  }
                  placeholder="Contoh: Kopi Senja"
                />
              </div>

              <div className="space-y-2">
                <Label>Tipe Bisnis *</Label>
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                  {BUSINESS_TYPE_OPTIONS.map((opt) => (
                    <button
                      key={opt.value}
                      type="button"
                      onClick={() =>
                        updateProfile({
                          business_type: opt.value,
                        })
                      }
                      className={cn(
                        "rounded-lg border px-3 py-2.5 text-sm font-medium transition-colors",
                        progress.profile.business_type === opt.value
                          ? "border-primary bg-primary/10 text-primary"
                          : "border-input hover:bg-slate-50",
                      )}
                    >
                      {opt.label}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-2">
                <Label>Logo Toko</Label>
                <div className="flex items-center gap-4">
                  <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-xl border border-dashed border-input bg-slate-50">
                    {logoPreview ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img
                        src={logoPreview}
                        alt="Logo preview"
                        className="h-full w-full object-cover"
                      />
                    ) : (
                      <Store className="h-8 w-8 text-muted-foreground" />
                    )}
                  </div>
                  <div>
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={(e) =>
                        handleLogoChange(e.target.files?.[0] ?? null)
                      }
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onClick={() => fileInputRef.current?.click()}
                      isLoading={logoUploading}
                      disabled={logoUploading}
                    >
                      <Upload className="h-4 w-4" />
                      Upload Logo
                    </Button>
                    <p className="mt-1 text-xs text-muted-foreground">
                      PNG/JPG, maks. 5MB
                    </p>
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="address">Alamat *</Label>
                <Input
                  id="address"
                  value={progress.profile.address}
                  onChange={(e) => updateProfile({ address: e.target.value })}
                  placeholder="Jl. Contoh No. 1, Jakarta"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="phone">Nomor WhatsApp *</Label>
                <Input
                  id="phone"
                  value={progress.profile.phone}
                  onChange={(e) => updateProfile({ phone: e.target.value })}
                  placeholder="08xxxxxxxxxx"
                />
              </div>
            </div>
          )}

          {currentStep === 2 && (
            <div className="space-y-5 rounded-xl border border-border bg-white p-6 shadow-sm">
              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="outlet_name">Nama Outlet *</Label>
                  <Input
                    id="outlet_name"
                    value={progress.outlet.name}
                    onChange={(e) => updateOutlet({ name: e.target.value })}
                    placeholder="Outlet Utama"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="outlet_code">Kode Outlet *</Label>
                  <Input
                    id="outlet_code"
                    value={progress.outlet.code}
                    onChange={(e) =>
                      updateOutlet({ code: e.target.value.toUpperCase() })
                    }
                    placeholder="OUT01"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="timezone">Timezone *</Label>
                <select
                  id="timezone"
                  value={progress.outlet.timezone}
                  onChange={(e) => updateOutlet({ timezone: e.target.value })}
                  className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                >
                  {TIMEZONE_OPTIONS.map((tz) => (
                    <option key={tz.value} value={tz.value}>
                      {tz.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="space-y-3">
                <Label>Fitur Aktif</Label>
                {[
                  {
                    key: "feature_reservations" as const,
                    label: "Reservasi",
                    desc: "Kelola booking meja pelanggan",
                  },
                  {
                    key: "feature_delivery" as const,
                    label: "Delivery",
                    desc: "Pesanan antar dan tracking driver",
                  },
                  {
                    key: "feature_qr_menu" as const,
                    label: "Menu Digital (QR)",
                    desc: "Menu scan QR untuk pelanggan",
                  },
                ].map((feature) => (
                  <label
                    key={feature.key}
                    className="flex cursor-pointer items-center justify-between rounded-lg border border-input px-4 py-3 hover:bg-slate-50"
                  >
                    <div>
                      <p className="text-sm font-medium">{feature.label}</p>
                      <p className="text-xs text-muted-foreground">
                        {feature.desc}
                      </p>
                    </div>
                    <input
                      type="checkbox"
                      checked={progress.outlet[feature.key]}
                      onChange={(e) =>
                        updateOutlet({ [feature.key]: e.target.checked })
                      }
                      className="h-4 w-4 rounded border-input text-primary focus:ring-primary"
                    />
                  </label>
                ))}
              </div>
            </div>
          )}

          {currentStep === 3 && (
            <div className="space-y-5 rounded-xl border border-border bg-white p-6 shadow-sm">
              <div className="space-y-2">
                <Label htmlFor="product_name">Nama Produk *</Label>
                <Input
                  id="product_name"
                  value={progress.product.name}
                  onChange={(e) => updateProduct({ name: e.target.value })}
                  placeholder="Contoh: Espresso"
                />
              </div>

              <div className="grid gap-4 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="product_price">Harga (Rp) *</Label>
                  <Input
                    id="product_price"
                    type="number"
                    min={0}
                    value={progress.product.base_price}
                    onChange={(e) =>
                      updateProduct({ base_price: e.target.value })
                    }
                    placeholder="25000"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="category_name">Kategori Baru *</Label>
                  <Input
                    id="category_name"
                    value={progress.product.category_name}
                    onChange={(e) =>
                      updateProduct({ category_name: e.target.value })
                    }
                    placeholder="Minuman"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="product_image">Foto Produk (opsional)</Label>
                <div className="flex items-center gap-4">
                  {progress.product.image_url ? (
                    <div className="h-16 w-16 overflow-hidden rounded-lg border border-border bg-slate-50">
                      {/* eslint-disable-next-line @next/next/no-img-element */}
                      <img
                        src={progress.product.image_url}
                        alt="Produk"
                        className="h-full w-full object-cover"
                      />
                    </div>
                  ) : null}
                  <label className="cursor-pointer">
                    <input
                      id="product_image"
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={async (e) => {
                        const file = e.target.files?.[0];
                        if (!file) return;
                        if (!file.type.startsWith("image/")) {
                          toast.error("File harus berupa gambar");
                          return;
                        }
                        if (file.size > 5 * 1024 * 1024) {
                          toast.error("Ukuran gambar maksimal 5MB");
                          return;
                        }
                        try {
                          const result = await uploadFile(file, "product");
                          updateProduct({ image_url: result.url });
                          toast.success("Gambar produk berhasil diunggah");
                        } catch (error) {
                          toast.error(getErrorMessage(error));
                        }
                      }}
                    />
                    <span className="inline-flex h-9 items-center gap-2 rounded-lg border border-border bg-white px-3 text-sm hover:bg-slate-50">
                      <Upload className="h-4 w-4" />
                      Unggah Gambar
                    </span>
                  </label>
                </div>
              </div>
            </div>
          )}

          {currentStep === 4 && (
            <div className="space-y-3 rounded-xl border border-border bg-white p-6 shadow-sm">
              <p className="text-sm text-muted-foreground">
                Centang metode pembayaran yang tersedia di kasir.
              </p>
              <div className="grid gap-2 sm:grid-cols-2">
                {PAYMENT_METHOD_OPTIONS.map((method) => {
                  const checked = progress.payment.selected.includes(
                    method.code,
                  );
                  return (
                    <label
                      key={method.code}
                      className={cn(
                        "flex cursor-pointer items-center gap-3 rounded-lg border px-4 py-3 transition-colors",
                        checked
                          ? "border-primary bg-primary/5"
                          : "border-input hover:bg-slate-50",
                      )}
                    >
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={() => togglePayment(method.code)}
                        className="h-4 w-4 rounded border-input text-primary focus:ring-primary"
                      />
                      <span className="text-sm font-medium">{method.label}</span>
                      {checked && (
                        <Check className="ml-auto h-4 w-4 text-primary" />
                      )}
                    </label>
                  );
                })}
              </div>
            </div>
          )}

          {currentStep === 5 && (
            <div className="space-y-5 rounded-xl border border-border bg-white p-6 shadow-sm">
              <div className="space-y-2">
                <Label htmlFor="staff_email">Email Staff</Label>
                <Input
                  id="staff_email"
                  type="email"
                  value={progress.staff.email}
                  onChange={(e) => updateStaff({ email: e.target.value })}
                  placeholder="kasir@toko.com"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="staff_name">Nama (opsional)</Label>
                <Input
                  id="staff_name"
                  value={progress.staff.name}
                  onChange={(e) => updateStaff({ name: e.target.value })}
                  placeholder="Nama kasir / manager"
                />
              </div>

              <div className="space-y-2">
                <Label>Role *</Label>
                <div className="grid grid-cols-2 gap-2">
                  {(["cashier", "manager"] as const).map((role) => (
                    <button
                      key={role}
                      type="button"
                      onClick={() => updateStaff({ role })}
                      className={cn(
                        "rounded-lg border px-4 py-3 text-sm font-medium capitalize transition-colors",
                        progress.staff.role === role
                          ? "border-primary bg-primary/10 text-primary"
                          : "border-input hover:bg-slate-50",
                      )}
                    >
                      {role === "cashier" ? "Kasir" : "Manager"}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </main>

      <footer className="border-t border-border bg-white px-6 py-4 shadow-[0_-4px_20px_rgba(0,0,0,0.04)]">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-3">
          <Button
            type="button"
            variant="ghost"
            disabled={currentStep <= 1 || submitting}
            onClick={() => setCurrentStep(currentStep - 1)}
          >
            <ChevronLeft className="h-4 w-4" />
            Kembali
          </Button>

          <div className="flex items-center gap-2">
            {isSkippable && (
              <Button
                type="button"
                variant="outline"
                disabled={submitting}
                onClick={handleSkip}
              >
                {currentStep === 5 ? "Lewati & Selesai" : "Lewati, tambah nanti"}
              </Button>
            )}

            <Button
              type="button"
              disabled={!canProceed || submitting}
              isLoading={submitting}
              onClick={handleNext}
            >
              {currentStep === 5 ? "Selesai & Mulai" : "Lanjut"}
              {currentStep < 5 && <ChevronRight className="h-4 w-4" />}
            </Button>
          </div>
        </div>
      </footer>
    </div>
  );
}