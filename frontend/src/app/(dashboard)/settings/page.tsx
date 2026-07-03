"use client";

import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  Building2,
  Coins,
  CreditCard,
  LayoutGrid,
  Pencil,
  Plug,
  Plus,
  Store,
  Upload,
  Users,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { QueryErrorState } from "@/components/ui/query-error-state";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import { InvoicePaymentDialog } from "@/components/billing/invoice-payment-dialog";
import { OperationsPanel } from "@/components/settings/operations-panel";
import { OutletFormDialog } from "@/components/settings/outlet-form-dialog";
import {
  getInvoices,
  getSubscription,
  setupRecurringSubscription,
} from "@/lib/api/billing";
import {
  getIntegrations,
  getSettingsOutlets,
  getSettingsUsers,
  getTenantSettings,
  syncPaymentMethods,
  updateTenantSettings,
  testEmailIntegration,
  testWhatsappIntegration,
  updateEmailIntegration,
  updateWhatsappIntegration,
} from "@/lib/api/settings";
import { usePackageFeatures } from "@/hooks/usePackageFeatures";
import { getPointConfig, updatePointConfig } from "@/lib/api/loyalty";
import { uploadFile } from "@/lib/api/uploads";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import { PAYMENT_METHOD_OPTIONS } from "@/types/onboarding";
import type { BillingInvoice, SettingsOutlet } from "@/types/settings";

type SettingsTab =
  | "business"
  | "outlets"
  | "operations"
  | "loyalty"
  | "users"
  | "subscription"
  | "integrations";

const tabs: { key: SettingsTab; label: string; icon: typeof Building2 }[] = [
  { key: "business", label: "Bisnis", icon: Building2 },
  { key: "outlets", label: "Outlet", icon: Store },
  { key: "operations", label: "Operasional", icon: LayoutGrid },
  { key: "loyalty", label: "Loyalty", icon: Coins },
  { key: "users", label: "Pengguna", icon: Users },
  { key: "subscription", label: "Langganan", icon: CreditCard },
  { key: "integrations", label: "Integrasi", icon: Plug },
];

const subscriptionStatusLabels: Record<string, string> = {
  active: "Aktif",
  trial: "Trial",
  past_due: "Jatuh Tempo",
  suspended: "Ditangguhkan",
  cancelled: "Dibatalkan",
  expired: "Kedaluwarsa",
};

const subscriptionStatusColors: Record<string, string> = {
  active: "bg-emerald-50 text-emerald-700",
  trial: "bg-sky-50 text-sky-700",
  past_due: "bg-amber-50 text-amber-700",
  suspended: "bg-rose-50 text-rose-700",
  cancelled: "bg-slate-100 text-slate-600",
  expired: "bg-slate-100 text-slate-600",
};

const invoiceStatusLabels: Record<string, string> = {
  draft: "Draft",
  sent: "Terkirim",
  paid: "Lunas",
  overdue: "Terlambat",
  cancelled: "Dibatalkan",
};

export default function SettingsPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<SettingsTab>("business");

  const [businessName, setBusinessName] = useState("");
  const [phone, setPhone] = useState("");
  const [address, setAddress] = useState("");
  const [email, setEmail] = useState("");
  const [taxRate, setTaxRate] = useState("0");
  const [serviceChargeRate, setServiceChargeRate] = useState("0");
  const [logoUrl, setLogoUrl] = useState("");
  const [logoUploading, setLogoUploading] = useState(false);
  const [selectedPayments, setSelectedPayments] = useState<string[]>(["cash"]);

  const [outletFormOpen, setOutletFormOpen] = useState(false);
  const [editingOutlet, setEditingOutlet] = useState<SettingsOutlet | null>(null);

  const [waPhone, setWaPhone] = useState("");
  const [waToken, setWaToken] = useState("");
  const [waActive, setWaActive] = useState(false);
  const [waGateway, setWaGateway] = useState<"fonnte" | "wablas" | "meta">("fonnte");
  const [waApiUrl, setWaApiUrl] = useState("");
  const [waTestPhone, setWaTestPhone] = useState("");

  const [emailActive, setEmailActive] = useState(false);
  const [emailMailer, setEmailMailer] = useState<"smtp" | "log">("smtp");
  const [emailHost, setEmailHost] = useState("");
  const [emailPort, setEmailPort] = useState("587");
  const [emailEncryption, setEmailEncryption] = useState<"tls" | "ssl" | "none">("tls");
  const [emailUsername, setEmailUsername] = useState("");
  const [emailPassword, setEmailPassword] = useState("");
  const [emailFromAddress, setEmailFromAddress] = useState("");
  const [emailFromName, setEmailFromName] = useState("");
  const [emailSendWelcome, setEmailSendWelcome] = useState(true);
  const [emailTestAddress, setEmailTestAddress] = useState("");

  const [payInvoice, setPayInvoice] = useState<BillingInvoice | null>(null);

  const [earnAmount, setEarnAmount] = useState("10000");
  const [earnPoints, setEarnPoints] = useState("1");
  const [redeemPoints, setRedeemPoints] = useState("100");
  const [redeemValue, setRedeemValue] = useState("10000");
  const [minRedeemPoints, setMinRedeemPoints] = useState("100");

  const [featureReservations, setFeatureReservations] = useState(true);
  const [featureDelivery, setFeatureDelivery] = useState(true);
  const [featureQrMenu, setFeatureQrMenu] = useState(true);
  const [wifiSsid, setWifiSsid] = useState("");
  const [wifiPassword, setWifiPassword] = useState("");
  const [receiptShowWifi, setReceiptShowWifi] = useState(false);

  const { hasPackageFeature } = usePackageFeatures();

  const {
    data: tenantSettings,
    isLoading: settingsLoading,
    isError: settingsError,
    error: settingsQueryError,
    refetch: refetchSettings,
  } = useQuery({
    queryKey: ["settings", "tenant"],
    queryFn: getTenantSettings,
    staleTime: 60 * 1000,
  });

  const { data: outlets = [], isLoading: outletsLoading } = useQuery({
    queryKey: ["settings", "outlets"],
    queryFn: getSettingsOutlets,
    staleTime: 60 * 1000,
    enabled: activeTab === "outlets",
  });

  const { data: subscription, isLoading: subLoading } = useQuery({
    queryKey: ["billing", "subscription"],
    queryFn: getSubscription,
    staleTime: 60 * 1000,
    enabled: activeTab === "subscription",
  });

  const { data: invoices = [], isLoading: invoicesLoading } = useQuery({
    queryKey: ["billing", "invoices"],
    queryFn: () => getInvoices({ per_page: 20 }),
    staleTime: 60 * 1000,
    enabled: activeTab === "subscription",
  });

  const { data: pointConfig } = useQuery({
    queryKey: ["loyalty", "point-config"],
    queryFn: getPointConfig,
    staleTime: 60 * 1000,
    enabled: activeTab === "loyalty",
  });

  const { data: usersData, isLoading: usersLoading } = useQuery({
    queryKey: ["settings", "users"],
    queryFn: () => getSettingsUsers({ per_page: 20 }),
    staleTime: 60 * 1000,
    enabled: activeTab === "users",
  });

  const { data: integrations = [] } = useQuery({
    queryKey: ["settings", "integrations"],
    queryFn: getIntegrations,
    staleTime: 60 * 1000,
    enabled: activeTab === "integrations",
  });

  useEffect(() => {
    if (!tenantSettings) return;
    setBusinessName(tenantSettings.business_name ?? "");
    setPhone(tenantSettings.phone ?? "");
    setAddress(tenantSettings.address ?? "");
    setEmail(tenantSettings.email ?? "");
    setTaxRate(String(tenantSettings.tax_rate ?? 0));
    setServiceChargeRate(String(tenantSettings.service_charge_rate ?? 0));
    setLogoUrl(tenantSettings.logo_url ?? "");
    setSelectedPayments(
      tenantSettings.enabled_payment_methods?.length
        ? tenantSettings.enabled_payment_methods
        : ["cash"]
    );
    setFeatureReservations(tenantSettings.feature_reservations ?? true);
    setFeatureDelivery(tenantSettings.feature_delivery ?? true);
    setFeatureQrMenu(tenantSettings.feature_qr_menu ?? true);
    setWifiSsid(tenantSettings.wifi_ssid ?? "");
    setWifiPassword(tenantSettings.wifi_password ?? "");
    setReceiptShowWifi(tenantSettings.receipt_show_wifi ?? false);
  }, [tenantSettings]);

  useEffect(() => {
    if (!pointConfig) return;
    setEarnAmount(String(pointConfig.earn_amount));
    setEarnPoints(String(pointConfig.earn_points));
    setRedeemPoints(String(pointConfig.redeem_points));
    setRedeemValue(String(pointConfig.redeem_value));
    setMinRedeemPoints(String(pointConfig.min_redeem_points));
  }, [pointConfig]);

  useEffect(() => {
    const emailIntegration = integrations.find((i) => i.provider === "email");
    if (emailIntegration) {
      setEmailActive(emailIntegration.is_active);
      const cfg = emailIntegration.config;
      const mailer = cfg?.mailer;
      if (mailer === "smtp" || mailer === "log") {
        setEmailMailer(mailer);
      }
      setEmailHost(String(cfg?.host ?? ""));
      setEmailPort(String(cfg?.port ?? 587));
      const enc = cfg?.encryption;
      if (enc === "tls" || enc === "ssl" || enc === "none") {
        setEmailEncryption(enc);
      } else if (!enc) {
        setEmailEncryption("none");
      }
      setEmailUsername(String(cfg?.username ?? ""));
      setEmailPassword(String(cfg?.password ?? ""));
      setEmailFromAddress(String(cfg?.from_address ?? ""));
      setEmailFromName(String(cfg?.from_name ?? ""));
      setEmailSendWelcome(cfg?.send_welcome_email !== false);
    }

    const wa = integrations.find((i) => i.provider === "whatsapp");
    if (!wa) return;
    setWaActive(wa.is_active);
    setWaPhone(String(wa.config?.phone ?? wa.config?.phone_number_id ?? ""));
    setWaToken(String(wa.config?.access_token ?? ""));
    const gateway = wa.config?.gateway;
    if (gateway === "fonnte" || gateway === "wablas" || gateway === "meta") {
      setWaGateway(gateway);
    }
    setWaApiUrl(String(wa.config?.api_url ?? ""));
  }, [integrations]);

  const saveBusinessMutation = useMutation({
    mutationFn: async () => {
      await syncPaymentMethods(selectedPayments);
      return updateTenantSettings({
        business_name: businessName,
        phone,
        address,
        email,
        logo_url: logoUrl || undefined,
        tax_rate: Number(taxRate) || 0,
        service_charge_rate: Number(serviceChargeRate) || 0,
        feature_reservations: featureReservations,
        feature_delivery: featureDelivery,
        feature_qr_menu: featureQrMenu,
        wifi_ssid: wifiSsid || undefined,
        wifi_password: wifiPassword || undefined,
        receipt_show_wifi: receiptShowWifi,
      });
    },
    onSuccess: () => {
      toast.success("Profil bisnis disimpan");
      queryClient.invalidateQueries({ queryKey: ["settings"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const handleLogoUpload = async (file: File) => {
    if (!file.type.startsWith("image/")) {
      toast.error("File harus berupa gambar");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast.error("Ukuran logo maksimal 5MB");
      return;
    }

    setLogoUploading(true);
    try {
      const result = await uploadFile(file, "logo");
      setLogoUrl(result.url);
      toast.success("Logo berhasil diunggah");
    } catch (e) {
      toast.error(getErrorMessage(e));
    } finally {
      setLogoUploading(false);
    }
  };

  const togglePayment = (code: string) => {
    setSelectedPayments((prev) => {
      if (prev.includes(code)) {
        if (prev.length === 1) {
          toast.error("Minimal satu metode pembayaran harus aktif");
          return prev;
        }
        return prev.filter((c) => c !== code);
      }
      return [...prev, code];
    });
  };

  const saveLoyaltyMutation = useMutation({
    mutationFn: () =>
      updatePointConfig({
        earn_amount: Number(earnAmount),
        earn_points: Number(earnPoints),
        redeem_points: Number(redeemPoints),
        redeem_value: Number(redeemValue),
        min_redeem_points: Number(minRedeemPoints),
        is_active: true,
      }),
    onSuccess: () => {
      toast.success("Konfigurasi loyalty disimpan");
      queryClient.invalidateQueries({ queryKey: ["loyalty"] });
      queryClient.invalidateQueries({ queryKey: ["members"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const hasEmailPasswordInput =
    emailPassword.length > 0 &&
    !emailPassword.startsWith("••") &&
    !emailPassword.includes("*");

  const saveEmailMutation = useMutation({
    mutationFn: () =>
      updateEmailIntegration({
        mailer: emailMailer,
        host: emailHost || undefined,
        port: Number(emailPort) || 587,
        encryption: emailEncryption === "none" ? null : emailEncryption,
        username: emailUsername || undefined,
        password: hasEmailPasswordInput ? emailPassword : undefined,
        from_address: emailFromAddress || undefined,
        from_name: emailFromName || undefined,
        send_welcome_email: emailSendWelcome,
        is_active: emailActive,
      }),
    onSuccess: () => {
      toast.success("Gateway email disimpan");
      queryClient.invalidateQueries({ queryKey: ["settings", "integrations"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const testEmailMutation = useMutation({
    mutationFn: () =>
      testEmailIntegration({
        email: emailTestAddress,
        mailer: emailMailer,
        host: emailHost || undefined,
        port: Number(emailPort) || 587,
        encryption: emailEncryption,
        username: emailUsername || undefined,
        password: hasEmailPasswordInput ? emailPassword : undefined,
        from_address: emailFromAddress || undefined,
        from_name: emailFromName || undefined,
        is_active: emailActive,
        send_welcome_email: emailSendWelcome,
        save_config: true,
      }),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ["settings", "integrations"] });
      if (result.mode === "log") {
        toast.info(result.message);
      } else {
        toast.success(result.message);
      }
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const saveWhatsappMutation = useMutation({
    mutationFn: () =>
      updateWhatsappIntegration({
        phone: waPhone,
        access_token: waToken && !waToken.startsWith("••") ? waToken : undefined,
        gateway: waGateway,
        api_url: waApiUrl || undefined,
        is_active: waActive,
      }),
    onSuccess: () => {
      toast.success("Integrasi WhatsApp disimpan");
      queryClient.invalidateQueries({ queryKey: ["settings", "integrations"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const hasWaTokenInput =
    waToken.length > 0 && !waToken.startsWith("••") && !waToken.includes("*");

  const testWhatsappMutation = useMutation({
    mutationFn: () =>
      testWhatsappIntegration({
        phone: waTestPhone,
        message: "Ini pesan uji coba dari CreativePOS. Integrasi WhatsApp berhasil dikonfigurasi.",
        gateway: waGateway,
        api_token: hasWaTokenInput ? waToken : undefined,
        api_url: waApiUrl || undefined,
        sender_phone: waPhone || undefined,
        is_active: waActive,
        save_config: true,
      }),
    onSuccess: (result) => {
      queryClient.invalidateQueries({ queryKey: ["settings", "integrations"] });
      if (result.mode === "dev") {
        toast.info(result.message);
      } else {
        toast.success(result.message);
      }
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const recurringMutation = useMutation({
    mutationFn: setupRecurringSubscription,
    onSuccess: (result) => {
      toast.success("Setup langganan otomatis berhasil");
      if (result.payment_url) {
        window.open(result.payment_url, "_blank");
      }
      queryClient.invalidateQueries({ queryKey: ["billing"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Pengaturan</h1>
        <p className="mt-1 text-muted-foreground">
          Kelola profil bisnis, outlet, langganan, dan integrasi
        </p>
      </div>

      <div className="flex gap-2 overflow-x-auto border-b border-border">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => setActiveTab(tab.key)}
              className={`flex shrink-0 items-center gap-2 border-b-2 px-4 py-2.5 text-sm font-medium transition-colors ${
                activeTab === tab.key
                  ? "border-primary text-primary"
                  : "border-transparent text-muted-foreground hover:text-foreground"
              }`}
            >
              <Icon className="h-4 w-4" />
              {tab.label}
            </button>
          );
        })}
      </div>

      {activeTab === "business" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Profil Bisnis</CardTitle>
            <CardDescription>
              Informasi dasar bisnis Anda
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 max-w-xl">
            {settingsLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 4 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-10 animate-pulse rounded-lg bg-slate-100"
                  />
                ))}
              </div>
            ) : settingsError ? (
              <QueryErrorState
                message={getErrorMessage(settingsQueryError)}
                onRetry={() => void refetchSettings()}
              />
            ) : (
              <>
                <div>
                  <Label htmlFor="businessName">Nama Bisnis</Label>
                  <Input
                    id="businessName"
                    value={businessName}
                    onChange={(e) => setBusinessName(e.target.value)}
                    placeholder="Nama restoran / toko"
                  />
                </div>
                <div>
                  <Label htmlFor="phone">Telepon</Label>
                  <Input
                    id="phone"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="08xxxxxxxxxx"
                  />
                </div>
                <div>
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                  />
                </div>
                <div>
                  <Label htmlFor="address">Alamat</Label>
                  <textarea
                    id="address"
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    rows={3}
                    className="w-full rounded-lg border border-border px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                  />
                </div>

                <div className="space-y-2">
                  <Label>Logo Bisnis</Label>
                  <div className="flex items-center gap-4">
                    {logoUrl ? (
                      <div className="h-16 w-16 overflow-hidden rounded-lg border border-border bg-slate-50">
                        {/* eslint-disable-next-line @next/next/no-img-element */}
                        <img src={logoUrl} alt="Logo" className="h-full w-full object-contain" />
                      </div>
                    ) : (
                      <div className="flex h-16 w-16 items-center justify-center rounded-lg border border-dashed border-border bg-slate-50 text-xs text-muted-foreground">
                        Logo
                      </div>
                    )}
                    <label className="cursor-pointer">
                      <input
                        type="file"
                        accept="image/*"
                        className="hidden"
                        disabled={logoUploading}
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) void handleLogoUpload(file);
                        }}
                      />
                      <span className="inline-flex h-9 items-center gap-2 rounded-lg border border-border bg-white px-3 text-sm hover:bg-slate-50">
                        <Upload className="h-4 w-4" />
                        {logoUploading ? "Mengunggah..." : "Unggah Logo"}
                      </span>
                    </label>
                  </div>
                </div>

                <div className="space-y-3 rounded-lg border border-border p-4">
                  <div>
                    <Label>WiFi untuk Pelanggan (cetak di nota)</Label>
                    <p className="text-xs text-muted-foreground">
                      SSID dan password akan muncul di struk kasir bila diaktifkan
                    </p>
                  </div>
                  <div className="grid gap-4 sm:grid-cols-2">
                    <div>
                      <Label htmlFor="wifiSsid">Nama WiFi (SSID)</Label>
                      <Input
                        id="wifiSsid"
                        value={wifiSsid}
                        onChange={(e) => setWifiSsid(e.target.value)}
                        placeholder="CreativePOS-Guest"
                      />
                    </div>
                    <div>
                      <Label htmlFor="wifiPassword">Password WiFi</Label>
                      <Input
                        id="wifiPassword"
                        value={wifiPassword}
                        onChange={(e) => setWifiPassword(e.target.value)}
                        placeholder="password123"
                      />
                    </div>
                  </div>
                  <label className="flex cursor-pointer items-center gap-2 text-sm">
                    <input
                      type="checkbox"
                      checked={receiptShowWifi}
                      onChange={(e) => setReceiptShowWifi(e.target.checked)}
                    />
                    Tampilkan WiFi di nota/struk kasir
                  </label>
                </div>

                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <Label htmlFor="taxRate">Pajak (%)</Label>
                    <Input
                      id="taxRate"
                      type="number"
                      min={0}
                      max={100}
                      step={0.1}
                      value={taxRate}
                      onChange={(e) => setTaxRate(e.target.value)}
                    />
                  </div>
                  <div>
                    <Label htmlFor="serviceCharge">Service Charge (%)</Label>
                    <Input
                      id="serviceCharge"
                      type="number"
                      min={0}
                      max={100}
                      step={0.1}
                      value={serviceChargeRate}
                      onChange={(e) => setServiceChargeRate(e.target.value)}
                    />
                  </div>
                </div>

                {(hasPackageFeature("reservation") ||
                  hasPackageFeature("delivery")) && (
                  <div className="space-y-2 rounded-lg border border-border p-4">
                    <Label>Fitur Operasional</Label>
                    <p className="text-xs text-muted-foreground">
                      Aktifkan/nonaktifkan modul sesuai kebutuhan bisnis
                    </p>
                    <div className="space-y-2">
                      {hasPackageFeature("reservation") && (
                        <label className="flex cursor-pointer items-center gap-2 text-sm">
                          <input
                            type="checkbox"
                            checked={featureReservations}
                            onChange={(e) =>
                              setFeatureReservations(e.target.checked)
                            }
                          />
                          Reservasi Meja
                        </label>
                      )}
                      {hasPackageFeature("delivery") && (
                        <label className="flex cursor-pointer items-center gap-2 text-sm">
                          <input
                            type="checkbox"
                            checked={featureDelivery}
                            onChange={(e) =>
                              setFeatureDelivery(e.target.checked)
                            }
                          />
                          Delivery / Pengantaran
                        </label>
                      )}
                      <label className="flex cursor-pointer items-center gap-2 text-sm">
                        <input
                          type="checkbox"
                          checked={featureQrMenu}
                          onChange={(e) => setFeatureQrMenu(e.target.checked)}
                        />
                        QR Menu (pesanan mandiri)
                      </label>
                    </div>
                  </div>
                )}

                <div className="space-y-2">
                  <Label>Metode Pembayaran POS</Label>
                  <div className="grid gap-2 sm:grid-cols-2">
                    {PAYMENT_METHOD_OPTIONS.map((method) => (
                      <label
                        key={method.code}
                        className="flex cursor-pointer items-center gap-2 rounded-lg border border-border px-3 py-2 text-sm hover:bg-slate-50"
                      >
                        <input
                          type="checkbox"
                          checked={selectedPayments.includes(method.code)}
                          onChange={() => togglePayment(method.code)}
                        />
                        {method.label}
                      </label>
                    ))}
                  </div>
                </div>

                <Button
                  onClick={() => saveBusinessMutation.mutate()}
                  isLoading={saveBusinessMutation.isPending}
                  disabled={!tenantSettings}
                >
                  Simpan Perubahan
                </Button>
              </>
            )}
          </CardContent>
        </Card>
      )}

      {activeTab === "outlets" && (
        <Card>
          <CardHeader className="flex flex-row items-start justify-between gap-4">
            <div>
              <CardTitle className="text-base">Daftar Outlet</CardTitle>
              <CardDescription>
                Outlet yang terdaftar di akun Anda
              </CardDescription>
            </div>
            <Button
              size="sm"
              onClick={() => {
                setEditingOutlet(null);
                setOutletFormOpen(true);
              }}
            >
              <Plus className="h-4 w-4" />
              Tambah
            </Button>
          </CardHeader>
          <CardContent>
            {outletsLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 3 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-16 animate-pulse rounded-lg bg-slate-100"
                  />
                ))}
              </div>
            ) : outlets.length === 0 ? (
              <div className="flex flex-col items-center py-12 text-center">
                <p className="text-muted-foreground">Belum ada outlet</p>
                <Button
                  className="mt-4"
                  size="sm"
                  onClick={() => {
                    setEditingOutlet(null);
                    setOutletFormOpen(true);
                  }}
                >
                  <Plus className="h-4 w-4" />
                  Tambah Outlet Pertama
                </Button>
              </div>
            ) : (
              <div className="space-y-3">
                {outlets.map((outlet) => (
                  <div
                    key={outlet.uuid}
                    className="flex items-center justify-between rounded-lg border border-border p-4"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <p className="font-medium">{outlet.name}</p>
                        {outlet.is_default && (
                          <span className="rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-medium text-primary">
                            Default
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground">
                        {outlet.code}
                        {outlet.address && ` · ${outlet.address}`}
                      </p>
                      {outlet.phone && (
                        <p className="text-xs text-muted-foreground">
                          {outlet.phone}
                        </p>
                      )}
                    </div>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingOutlet(outlet);
                          setOutletFormOpen(true);
                        }}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <span
                        className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                          outlet.is_active
                            ? "bg-emerald-50 text-emerald-700"
                            : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {outlet.is_active ? "Aktif" : "Nonaktif"}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      <OutletFormDialog
        open={outletFormOpen}
        outlet={editingOutlet}
        onClose={() => {
          setOutletFormOpen(false);
          setEditingOutlet(null);
        }}
        onSuccess={() => {
          queryClient.invalidateQueries({ queryKey: ["settings", "outlets"] });
          queryClient.invalidateQueries({ queryKey: ["dashboard", "outlets"] });
        }}
      />

      {activeTab === "operations" && <OperationsPanel />}

      {activeTab === "loyalty" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Konfigurasi Poin</CardTitle>
            <CardDescription>
              Atur aturan earn dan redeem poin loyalitas
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 max-w-xl">
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <Label>Belanja (Rp) untuk earn</Label>
                <Input
                  type="number"
                  value={earnAmount}
                  onChange={(e) => setEarnAmount(e.target.value)}
                />
              </div>
              <div>
                <Label>Poin didapat</Label>
                <Input
                  type="number"
                  value={earnPoints}
                  onChange={(e) => setEarnPoints(e.target.value)}
                />
              </div>
              <div>
                <Label>Poin untuk redeem</Label>
                <Input
                  type="number"
                  value={redeemPoints}
                  onChange={(e) => setRedeemPoints(e.target.value)}
                />
              </div>
              <div>
                <Label>Nilai redeem (Rp)</Label>
                <Input
                  type="number"
                  value={redeemValue}
                  onChange={(e) => setRedeemValue(e.target.value)}
                />
              </div>
            </div>
            <div>
              <Label>Minimal redeem (poin)</Label>
              <Input
                type="number"
                value={minRedeemPoints}
                onChange={(e) => setMinRedeemPoints(e.target.value)}
              />
            </div>
            <Button
              onClick={() => saveLoyaltyMutation.mutate()}
              isLoading={saveLoyaltyMutation.isPending}
            >
              Simpan Konfigurasi
            </Button>
          </CardContent>
        </Card>
      )}

      {activeTab === "users" && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Pengguna & Staff</CardTitle>
            <CardDescription>
              Daftar pengguna yang terdaftar di bisnis Anda
            </CardDescription>
          </CardHeader>
          <CardContent>
            {usersLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 4 }).map((_, i) => (
                  <div key={i} className="h-12 animate-pulse rounded-lg bg-slate-100" />
                ))}
              </div>
            ) : (usersData?.data ?? []).length === 0 ? (
              <p className="py-8 text-center text-muted-foreground">
                Belum ada pengguna. Undang staff lewat wizard onboarding.
              </p>
            ) : (
              <div className="overflow-x-auto rounded-lg border border-border">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                    <tr>
                      <th className="px-4 py-3 font-medium">Nama</th>
                      <th className="px-4 py-3 font-medium">Email</th>
                      <th className="px-4 py-3 font-medium">Outlet</th>
                      <th className="px-4 py-3 font-medium">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {usersData?.data.map((user) => (
                      <tr key={user.id}>
                        <td className="px-4 py-3 font-medium">{user.name}</td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {user.email}
                        </td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {user.outlet?.name ?? "—"}
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                              user.status === "active"
                                ? "bg-emerald-50 text-emerald-700"
                                : "bg-slate-100 text-slate-600"
                            }`}
                          >
                            {user.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {activeTab === "subscription" && (
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Paket Langganan</CardTitle>
            </CardHeader>
            <CardContent>
              {subLoading ? (
                <div className="h-32 animate-pulse rounded-lg bg-slate-100" />
              ) : !subscription ? (
                <p className="text-muted-foreground">
                  Informasi langganan tidak tersedia
                </p>
              ) : (
                <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <h3 className="text-xl font-bold">
                      {subscription.package.name}
                    </h3>
                    <p className="mt-1 text-sm text-muted-foreground">
                      {subscription.package.description}
                    </p>
                    <p className="mt-3 text-2xl font-bold text-primary">
                      {formatCurrency(
                        subscription.billing_cycle === "yearly"
                          ? subscription.package.price_yearly
                          : subscription.package.price_monthly
                      )}
                      <span className="text-sm font-normal text-muted-foreground">
                        /{subscription.billing_cycle === "yearly" ? "tahun" : "bulan"}
                      </span>
                    </p>
                  </div>
                  <div className="space-y-2 text-sm">
                    <span
                      className={`inline-flex rounded-full px-3 py-1 text-xs font-medium ${
                        subscriptionStatusColors[subscription.status] ??
                        "bg-slate-100"
                      }`}
                    >
                      {subscriptionStatusLabels[subscription.status] ??
                        subscription.status}
                    </span>
                    {subscription.trial_ends_at && (
                      <p className="text-muted-foreground">
                        Trial berakhir:{" "}
                        {formatDate(subscription.trial_ends_at)}
                      </p>
                    )}
                    <p className="text-muted-foreground">
                      Siklus:{" "}
                      {subscription.billing_cycle === "yearly"
                        ? "Tahunan"
                        : "Bulanan"}
                    </p>
                    {subscription.next_billing_date && (
                      <p className="text-muted-foreground">
                        Tagihan berikutnya:{" "}
                        {formatDate(subscription.next_billing_date)}
                      </p>
                    )}
                    <Button
                      size="sm"
                      variant="outline"
                      className="mt-2"
                      onClick={() => recurringMutation.mutate()}
                      isLoading={recurringMutation.isPending}
                    >
                      Aktifkan Auto-Renew (Xendit)
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Riwayat Invoice</CardTitle>
              <CardDescription>Tagihan langganan Anda</CardDescription>
            </CardHeader>
            <CardContent>
              {invoicesLoading ? (
                <div className="space-y-3">
                  {Array.from({ length: 4 }).map((_, i) => (
                    <div
                      key={i}
                      className="h-12 animate-pulse rounded-lg bg-slate-100"
                    />
                  ))}
                </div>
              ) : invoices.length === 0 ? (
                <p className="py-8 text-center text-muted-foreground">
                  Belum ada invoice
                </p>
              ) : (
                <div className="overflow-x-auto rounded-lg border border-border">
                  <table className="w-full text-sm">
                    <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                      <tr>
                        <th className="px-4 py-3 font-medium">Invoice</th>
                        <th className="px-4 py-3 font-medium">Periode</th>
                        <th className="px-4 py-3 font-medium text-right">
                          Total
                        </th>
                        <th className="px-4 py-3 font-medium text-center">
                          Status
                        </th>
                        <th className="px-4 py-3 font-medium">Jatuh Tempo</th>
                        <th className="px-4 py-3 font-medium text-right">
                          Aksi
                        </th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border">
                      {invoices.map((inv) => (
                        <tr key={inv.id}>
                          <td className="px-4 py-3 font-medium">
                            {inv.invoice_number}
                          </td>
                          <td className="px-4 py-3 text-muted-foreground">
                            {formatDate(inv.period_start, {
                              day: "numeric",
                              month: "short",
                            })}{" "}
                            –{" "}
                            {formatDate(inv.period_end, {
                              day: "numeric",
                              month: "short",
                              year: "numeric",
                            })}
                          </td>
                          <td className="px-4 py-3 text-right font-medium">
                            {formatCurrency(inv.total_amount)}
                          </td>
                          <td className="px-4 py-3 text-center">
                            <span
                              className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                                inv.status === "paid"
                                  ? "bg-emerald-50 text-emerald-700"
                                  : inv.status === "overdue"
                                    ? "bg-rose-50 text-rose-700"
                                    : "bg-slate-100 text-slate-600"
                              }`}
                            >
                              {invoiceStatusLabels[inv.status] ?? inv.status}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-muted-foreground">
                            {formatDate(inv.due_date)}
                          </td>
                          <td className="px-4 py-3 text-right">
                            {inv.status !== "paid" &&
                            inv.status !== "cancelled" ? (
                              <Button
                                size="sm"
                                onClick={() => setPayInvoice(inv)}
                              >
                                Bayar
                              </Button>
                            ) : (
                              <span className="text-xs text-muted-foreground">
                                —
                              </span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>

          <InvoicePaymentDialog
            open={payInvoice !== null}
            invoice={payInvoice}
            onClose={() => setPayInvoice(null)}
            onSuccess={() => {
              queryClient.invalidateQueries({ queryKey: ["billing"] });
            }}
          />
        </div>
      )}

      {activeTab === "integrations" && (
        <div className="space-y-6">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Gateway Email (SMTP)</CardTitle>
            <CardDescription>
              Konfigurasi SMTP untuk email pendaftar, OTP, reset password, dan notifikasi
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 max-w-xl">
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="emailActive"
                checked={emailActive}
                onChange={(e) => setEmailActive(e.target.checked)}
                className="h-4 w-4 rounded border-border"
              />
              <Label htmlFor="emailActive">Aktifkan gateway email</Label>
            </div>
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="emailSendWelcome"
                checked={emailSendWelcome}
                onChange={(e) => setEmailSendWelcome(e.target.checked)}
                className="h-4 w-4 rounded border-border"
              />
              <Label htmlFor="emailSendWelcome">Kirim email selamat datang saat pendaftaran</Label>
            </div>
            <div>
              <Label htmlFor="emailMailer">Mode</Label>
              <select
                id="emailMailer"
                value={emailMailer}
                onChange={(e) => setEmailMailer(e.target.value as "smtp" | "log")}
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="smtp">SMTP (Gmail, Mailtrap, dll.)</option>
                <option value="log">Log (development)</option>
              </select>
            </div>
            {emailMailer === "smtp" && (
              <>
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <Label htmlFor="emailHost">SMTP Host</Label>
                    <Input
                      id="emailHost"
                      value={emailHost}
                      onChange={(e) => setEmailHost(e.target.value)}
                      placeholder="smtp.gmail.com"
                    />
                  </div>
                  <div>
                    <Label htmlFor="emailPort">Port</Label>
                    <Input
                      id="emailPort"
                      type="number"
                      value={emailPort}
                      onChange={(e) => setEmailPort(e.target.value)}
                      placeholder="587"
                    />
                  </div>
                </div>
                <div>
                  <Label htmlFor="emailEncryption">Enkripsi</Label>
                  <select
                    id="emailEncryption"
                    value={emailEncryption}
                    onChange={(e) =>
                      setEmailEncryption(e.target.value as "tls" | "ssl" | "none")
                    }
                    className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
                  >
                    <option value="tls">TLS (port 587)</option>
                    <option value="ssl">SSL (port 465)</option>
                    <option value="none">Tanpa enkripsi</option>
                  </select>
                </div>
                <div className="grid gap-4 sm:grid-cols-2">
                  <div>
                    <Label htmlFor="emailUsername">Username</Label>
                    <Input
                      id="emailUsername"
                      value={emailUsername}
                      onChange={(e) => setEmailUsername(e.target.value)}
                      placeholder="email@domain.com"
                    />
                  </div>
                  <div>
                    <Label htmlFor="emailPassword">Password / App Password</Label>
                    <Input
                      id="emailPassword"
                      type="password"
                      value={emailPassword}
                      onChange={(e) => setEmailPassword(e.target.value)}
                      placeholder="••••••••"
                    />
                  </div>
                </div>
              </>
            )}
            <div className="grid gap-4 sm:grid-cols-2">
              <div>
                <Label htmlFor="emailFromAddress">From Address</Label>
                <Input
                  id="emailFromAddress"
                  type="email"
                  value={emailFromAddress}
                  onChange={(e) => setEmailFromAddress(e.target.value)}
                  placeholder="noreply@bisnisanda.com"
                />
              </div>
              <div>
                <Label htmlFor="emailFromName">From Name</Label>
                <Input
                  id="emailFromName"
                  value={emailFromName}
                  onChange={(e) => setEmailFromName(e.target.value)}
                  placeholder={businessName || "Nama Bisnis"}
                />
              </div>
            </div>
            <div className="flex flex-wrap gap-2">
              <Button
                onClick={() => saveEmailMutation.mutate()}
                isLoading={saveEmailMutation.isPending}
              >
                Simpan Gateway Email
              </Button>
            </div>

            <div className="rounded-lg border border-dashed border-border bg-slate-50 p-4">
              <p className="text-sm font-medium">Uji Email</p>
              <p className="mt-1 text-xs text-muted-foreground">
                Isi konfigurasi SMTP di atas, lalu kirim email uji. Konfigurasi disimpan otomatis sebelum pengujian.
              </p>
              {emailMailer === "smtp" && !emailActive && (
                <p className="mt-2 text-xs text-amber-700">
                  Centang &quot;Aktifkan gateway email&quot; agar email benar-benar dikirim via SMTP.
                </p>
              )}
              <div className="mt-3 flex flex-col gap-3 sm:flex-row">
                <Input
                  type="email"
                  value={emailTestAddress}
                  onChange={(e) => setEmailTestAddress(e.target.value)}
                  placeholder="email@penerima.com"
                />
                <Button
                  variant="outline"
                  onClick={() => testEmailMutation.mutate()}
                  isLoading={testEmailMutation.isPending}
                  disabled={!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailTestAddress)}
                >
                  Simpan & Kirim Uji
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Integrasi WhatsApp</CardTitle>
            <CardDescription>
              Konfigurasi WhatsApp Business API untuk notifikasi dan CRM
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 max-w-xl">
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                id="waActive"
                checked={waActive}
                onChange={(e) => setWaActive(e.target.checked)}
                className="h-4 w-4 rounded border-border"
              />
              <Label htmlFor="waActive">Aktifkan integrasi WhatsApp</Label>
            </div>
            <div>
              <Label htmlFor="waGateway">Gateway</Label>
              <select
                id="waGateway"
                value={waGateway}
                onChange={(e) =>
                  setWaGateway(e.target.value as "fonnte" | "wablas" | "meta")
                }
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="fonnte">Fonnte</option>
                <option value="wablas">Wablas</option>
                <option value="meta">Meta (WhatsApp Business API)</option>
              </select>
            </div>
            <div>
              <Label htmlFor="waPhone">Nomor WhatsApp Pengirim</Label>
              <Input
                id="waPhone"
                value={waPhone}
                onChange={(e) => setWaPhone(e.target.value)}
                placeholder="628xxxxxxxxxx"
              />
            </div>
            {(waGateway === "wablas" || waGateway === "meta") && (
              <div>
                <Label htmlFor="waApiUrl">API URL</Label>
                <Input
                  id="waApiUrl"
                  value={waApiUrl}
                  onChange={(e) => setWaApiUrl(e.target.value)}
                  placeholder={
                    waGateway === "meta"
                      ? "https://graph.facebook.com/v21.0/{phone-number-id}/messages"
                      : "https://domain.wablas.com"
                  }
                />
              </div>
            )}
            <div>
              <Label htmlFor="waToken">API Token</Label>
              <Input
                id="waToken"
                type="password"
                value={waToken}
                onChange={(e) => setWaToken(e.target.value)}
                placeholder="Masukkan access token WhatsApp API"
              />
              <p className="mt-1 text-xs text-muted-foreground">
                Token disimpan terenkripsi di server
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              <Button
                onClick={() => saveWhatsappMutation.mutate()}
                isLoading={saveWhatsappMutation.isPending}
              >
                Simpan Integrasi
              </Button>
            </div>

            <div className="rounded-lg border border-dashed border-border bg-slate-50 p-4">
              <p className="text-sm font-medium">Uji Integrasi</p>
              <p className="mt-1 text-xs text-muted-foreground">
                Isi token API di atas, lalu kirim pesan uji. Konfigurasi akan disimpan otomatis sebelum pengujian.
              </p>
              {!waActive && (
                <p className="mt-2 text-xs text-amber-700">
                  Centang &quot;Aktifkan integrasi WhatsApp&quot; agar pesan benar-benar dikirim.
                </p>
              )}
              {!hasWaTokenInput && (
                <p className="mt-2 text-xs text-amber-700">
                  Masukkan API token Fonnte/Wablas/Meta (bukan titik-titik) sebelum uji coba.
                </p>
              )}
              <div className="mt-3 flex flex-col gap-3 sm:flex-row">
                <Input
                  value={waTestPhone}
                  onChange={(e) => setWaTestPhone(e.target.value)}
                  placeholder="08xxxxxxxxxx (nomor penerima)"
                />
                <Button
                  variant="outline"
                  onClick={() => testWhatsappMutation.mutate()}
                  isLoading={testWhatsappMutation.isPending}
                  disabled={
                    !/^08\d{8,12}$/.test(waTestPhone) || !waActive || !hasWaTokenInput
                  }
                >
                  Simpan & Kirim Uji
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
        </div>
      )}
    </div>
  );
}