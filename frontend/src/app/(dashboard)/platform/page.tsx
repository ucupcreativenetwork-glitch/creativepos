"use client";

import { useEffect, useRef, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import { Building2, DollarSign, Smartphone, Upload, Users } from "lucide-react";
import { KpiCard } from "@/components/dashboard/kpi-card";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { getErrorMessage } from "@/lib/api/client";
import {
  activateAppRelease,
  activatePlatformTenant,
  deleteAppRelease,
  getAppReleases,
  getPlatformDashboard,
  getPlatformTenants,
  suspendPlatformTenant,
  uploadAppRelease,
} from "@/lib/api/platform";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import { useAuthStore } from "@/stores/auth-store";

const tenantStatusLabels: Record<string, string> = {
  active: "Aktif",
  trial: "Trial",
  suspended: "Ditangguhkan",
  terminated: "Dihentikan",
};

export default function PlatformPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { user } = useAuthStore();

  useEffect(() => {
    if (user && !user.is_super_admin) {
      router.replace("/dashboard");
    }
  }, [user, router]);

  const { data: dashboard, isLoading: dashLoading } = useQuery({
    queryKey: ["platform", "dashboard"],
    queryFn: getPlatformDashboard,
    enabled: !!user?.is_super_admin,
    staleTime: 60 * 1000,
  });

  const { data: tenants = [], isLoading: tenantsLoading } = useQuery({
    queryKey: ["platform", "tenants"],
    queryFn: () => getPlatformTenants({ per_page: 50 }),
    enabled: !!user?.is_super_admin,
    staleTime: 60 * 1000,
  });

  const suspendMutation = useMutation({
    mutationFn: suspendPlatformTenant,
    onSuccess: () => {
      toast.success("Tenant ditangguhkan");
      queryClient.invalidateQueries({ queryKey: ["platform"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const activateMutation = useMutation({
    mutationFn: activatePlatformTenant,
    onSuccess: () => {
      toast.success("Tenant diaktifkan");
      queryClient.invalidateQueries({ queryKey: ["platform"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const fileRef = useRef<HTMLInputElement>(null);
  const [releaseVersion, setReleaseVersion] = useState("1.1.0");
  const [releaseBuild, setReleaseBuild] = useState("2");
  const [releaseNotes, setReleaseNotes] = useState("");
  const [mandatory, setMandatory] = useState(false);

  const { data: releases = [], isLoading: releasesLoading } = useQuery({
    queryKey: ["platform", "app-releases"],
    queryFn: getAppReleases,
    enabled: !!user?.is_super_admin,
  });

  const uploadReleaseMutation = useMutation({
    mutationFn: uploadAppRelease,
    onSuccess: () => {
      toast.success("APK berhasil diunggah — HP akan auto-update");
      queryClient.invalidateQueries({ queryKey: ["platform", "app-releases"] });
      if (fileRef.current) fileRef.current.value = "";
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const activateReleaseMutation = useMutation({
    mutationFn: activateAppRelease,
    onSuccess: () => {
      toast.success("Rilis diaktifkan");
      queryClient.invalidateQueries({ queryKey: ["platform", "app-releases"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const deleteReleaseMutation = useMutation({
    mutationFn: deleteAppRelease,
    onSuccess: () => {
      toast.success("Rilis dihapus");
      queryClient.invalidateQueries({ queryKey: ["platform", "app-releases"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const handleUploadRelease = () => {
    const file = fileRef.current?.files?.[0];
    if (!file) {
      toast.error("Pilih file APK terlebih dahulu");
      return;
    }
    const form = new FormData();
    form.append("file", file);
    form.append("version", releaseVersion);
    form.append("build_number", releaseBuild);
    form.append("platform", "android");
    if (releaseNotes.trim()) form.append("release_notes", releaseNotes.trim());
    if (mandatory) form.append("is_mandatory", "1");
    uploadReleaseMutation.mutate(form);
  };

  if (!user?.is_super_admin) {
    return (
      <div className="flex h-64 items-center justify-center text-muted-foreground">
        Memuat...
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Platform Admin</h1>
        <p className="mt-1 text-muted-foreground">
          Kelola tenant dan monitoring CreativePOS SaaS
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KpiCard
          title="Total Tenant"
          value={String(dashboard?.total_tenants ?? 0)}
          description={`Aktif: ${dashboard?.active_tenants ?? 0}`}
          icon={Building2}
          colorClass="text-blue-600 bg-blue-50"
          isLoading={dashLoading}
        />
        <KpiCard
          title="MRR"
          value={formatCurrency(dashboard?.mrr ?? 0)}
          description={`ARR: ${formatCurrency(dashboard?.arr ?? 0)}`}
          icon={DollarSign}
          colorClass="text-emerald-600 bg-emerald-50"
          isLoading={dashLoading}
        />
        <KpiCard
          title="Trial"
          value={String(dashboard?.trial_tenants ?? 0)}
          description="Tenant dalam masa trial"
          icon={Users}
          colorClass="text-sky-600 bg-sky-50"
          isLoading={dashLoading}
        />
        <KpiCard
          title="Ditangguhkan"
          value={String(dashboard?.suspended_tenants ?? 0)}
          description="Perlu ditinjau"
          icon={Building2}
          colorClass="text-rose-600 bg-rose-50"
          isLoading={dashLoading}
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Smartphone className="h-4 w-4" />
            Update Aplikasi Android
          </CardTitle>
          <CardDescription>
            Unggah APK baru — semua HP akan mendapat notifikasi update otomatis tanpa uninstall
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid gap-4 rounded-lg border border-dashed border-border p-4 sm:grid-cols-2 lg:grid-cols-4">
            <div className="space-y-2">
              <Label htmlFor="release_version">Versi</Label>
              <Input
                id="release_version"
                value={releaseVersion}
                onChange={(e) => setReleaseVersion(e.target.value)}
                placeholder="1.1.0"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="release_build">Build Number</Label>
              <Input
                id="release_build"
                type="number"
                value={releaseBuild}
                onChange={(e) => setReleaseBuild(e.target.value)}
                placeholder="2"
              />
            </div>
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="release_notes">Catatan Rilis</Label>
              <Input
                id="release_notes"
                value={releaseNotes}
                onChange={(e) => setReleaseNotes(e.target.value)}
                placeholder="Perbaikan bug, fitur baru..."
              />
            </div>
            <div className="space-y-2 sm:col-span-2">
              <Label htmlFor="apk_file">File APK</Label>
              <Input id="apk_file" ref={fileRef} type="file" accept=".apk" />
            </div>
            <div className="flex items-center gap-2 sm:col-span-2">
              <input
                id="mandatory"
                type="checkbox"
                checked={mandatory}
                onChange={(e) => setMandatory(e.target.checked)}
              />
              <Label htmlFor="mandatory">Update wajib (paksa install)</Label>
            </div>
            <div className="sm:col-span-2 lg:col-span-4">
              <Button
                onClick={handleUploadRelease}
                isLoading={uploadReleaseMutation.isPending}
              >
                <Upload className="mr-2 h-4 w-4" />
                Unggah & Aktifkan Rilis
              </Button>
            </div>
          </div>

          {releasesLoading ? (
            <div className="h-24 animate-pulse rounded-lg bg-slate-100" />
          ) : releases.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              Belum ada rilis APK. Unggah build pertama di atas.
            </p>
          ) : (
            <div className="overflow-x-auto rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-medium">Versi</th>
                    <th className="px-4 py-3 font-medium">Build</th>
                    <th className="px-4 py-3 font-medium">Ukuran</th>
                    <th className="px-4 py-3 font-medium text-center">Status</th>
                    <th className="px-4 py-3 font-medium text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {releases.map((release) => (
                    <tr key={release.id}>
                      <td className="px-4 py-3 font-medium">{release.version}</td>
                      <td className="px-4 py-3">{release.build_number}</td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {(release.file_size / 1024 / 1024).toFixed(1)} MB
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span
                          className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                            release.is_active
                              ? "bg-emerald-50 text-emerald-700"
                              : "bg-slate-100 text-slate-600"
                          }`}
                        >
                          {release.is_active ? "Aktif" : "Nonaktif"}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-right space-x-2">
                        {!release.is_active && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => activateReleaseMutation.mutate(release.id)}
                          >
                            Aktifkan
                          </Button>
                        )}
                        {!release.is_active && (
                          <Button
                            size="sm"
                            variant="ghost"
                            className="text-red-600"
                            onClick={() => deleteReleaseMutation.mutate(release.id)}
                          >
                            Hapus
                          </Button>
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

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Daftar Tenant</CardTitle>
          <CardDescription>
            Semua bisnis terdaftar di platform
          </CardDescription>
        </CardHeader>
        <CardContent>
          {tenantsLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 5 }).map((_, i) => (
                <div
                  key={i}
                  className="h-14 animate-pulse rounded-lg bg-slate-100"
                />
              ))}
            </div>
          ) : tenants.length === 0 ? (
            <p className="py-12 text-center text-muted-foreground">
              Belum ada tenant
            </p>
          ) : (
            <div className="overflow-x-auto rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-medium">Bisnis</th>
                    <th className="px-4 py-3 font-medium">Paket</th>
                    <th className="px-4 py-3 font-medium text-center">
                      Status
                    </th>
                    <th className="px-4 py-3 font-medium">Terdaftar</th>
                    <th className="px-4 py-3 font-medium text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {tenants.map((tenant) => (
                    <tr key={tenant.id}>
                      <td className="px-4 py-3">
                        <p className="font-medium">{tenant.name}</p>
                        <p className="text-xs text-muted-foreground">
                          {tenant.email}
                        </p>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {tenant.subscription?.package_name ?? "—"}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span
                          className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                            tenant.status === "active"
                              ? "bg-emerald-50 text-emerald-700"
                              : tenant.status === "trial"
                                ? "bg-sky-50 text-sky-700"
                                : "bg-slate-100 text-slate-600"
                          }`}
                        >
                          {tenantStatusLabels[tenant.status] ?? tenant.status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {formatDate(tenant.created_at, {
                          day: "numeric",
                          month: "short",
                          year: "numeric",
                        })}
                      </td>
                      <td className="px-4 py-3 text-right">
                        {tenant.status === "suspended" ? (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() => activateMutation.mutate(tenant.id)}
                            isLoading={
                              activateMutation.isPending &&
                              activateMutation.variables === tenant.id
                            }
                          >
                            Aktifkan
                          </Button>
                        ) : tenant.status !== "terminated" ? (
                          <Button
                            size="sm"
                            variant="ghost"
                            className="text-red-600"
                            onClick={() => suspendMutation.mutate(tenant.id)}
                            isLoading={
                              suspendMutation.isPending &&
                              suspendMutation.variables === tenant.id
                            }
                          >
                            Tangguhkan
                          </Button>
                        ) : null}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}