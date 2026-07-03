"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useRouter } from "next/navigation";
import {
  Activity,
  ArrowLeft,
  Cpu,
  Globe,
  MonitorSmartphone,
  RefreshCw,
  Terminal,
  Wifi,
} from "lucide-react";
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
import { KpiCard } from "@/components/dashboard/kpi-card";
import { getErrorMessage } from "@/lib/api/client";
import {
  getPlatformDeviceDetail,
  getPlatformDevices,
  getPlatformDeviceStats,
  sendPlatformDeviceCommand,
  type PlatformDevice,
} from "@/lib/api/platform";
import { formatDate } from "@/lib/utils/format";
import { useAuthStore } from "@/stores/auth-store";

const COMMANDS = [
  { id: "ping", label: "Ping" },
  { id: "collect_info", label: "Ambil Info Perangkat" },
  { id: "collect_logs", label: "Ambil Log" },
  { id: "check_update", label: "Cek Update" },
  { id: "force_sync", label: "Paksa Sync" },
  { id: "clear_cache", label: "Bersihkan Cache" },
  { id: "open_remote_assist", label: "Remote Assist" },
] as const;

export default function PlatformDevicesPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { user } = useAuthStore();
  const [search, setSearch] = useState("");
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [onlineOnly, setOnlineOnly] = useState(false);

  useEffect(() => {
    if (user && !user.is_super_admin) {
      router.replace("/dashboard");
    }
  }, [user, router]);

  const { data: stats } = useQuery({
    queryKey: ["platform", "devices", "stats"],
    queryFn: getPlatformDeviceStats,
    enabled: !!user?.is_super_admin,
    refetchInterval: 30_000,
  });

  const { data: devicesData, isLoading } = useQuery({
    queryKey: ["platform", "devices", search, onlineOnly],
    queryFn: () =>
      getPlatformDevices({
        search: search || undefined,
        online_only: onlineOnly,
        per_page: 50,
      }),
    enabled: !!user?.is_super_admin,
    refetchInterval: 30_000,
  });

  const { data: detail } = useQuery({
    queryKey: ["platform", "devices", selectedId],
    queryFn: () => getPlatformDeviceDetail(selectedId!),
    enabled: !!user?.is_super_admin && selectedId != null,
    refetchInterval: 10_000,
  });

  const commandMutation = useMutation({
    mutationFn: ({ id, command }: { id: number; command: string }) =>
      sendPlatformDeviceCommand(id, command),
    onSuccess: () => {
      toast.success("Perintah remote dikirim");
      queryClient.invalidateQueries({ queryKey: ["platform", "devices"] });
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const devices = devicesData?.items ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <Link
            href="/platform"
            className="mb-2 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" />
            Kembali ke Platform
          </Link>
          <h1 className="text-2xl font-bold">Remote Device Center</h1>
          <p className="text-sm text-muted-foreground">
            Pantau instalasi aplikasi, IP, device ID, dan kirim perintah remote
            untuk bug fixing.
          </p>
        </div>
        <Button
          variant="outline"
          onClick={() =>
            queryClient.invalidateQueries({ queryKey: ["platform", "devices"] })
          }
        >
          <RefreshCw className="h-4 w-4" />
          Refresh
        </Button>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <KpiCard
          title="Total Perangkat"
          value={String(stats?.total_devices ?? 0)}
          icon={MonitorSmartphone}
        />
        <KpiCard
          title="Online"
          value={String(stats?.online_devices ?? 0)}
          icon={Activity}
          description="Aktif 5 menit terakhir"
        />
        <KpiCard
          title="Android"
          value={String(stats?.android_devices ?? 0)}
          icon={Cpu}
        />
        <KpiCard
          title="Web"
          value={String(stats?.web_devices ?? 0)}
          icon={Globe}
        />
      </div>

      <div className="grid gap-6 xl:grid-cols-[1.4fr_1fr]">
        <Card>
          <CardHeader>
            <CardTitle>Daftar Instalasi</CardTitle>
            <CardDescription>
              Semua perangkat yang menjalankan remote agent CreativePOS
            </CardDescription>
            <div className="flex flex-wrap gap-2 pt-2">
              <Input
                placeholder="Cari nama, IP, MAC, email..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="max-w-sm"
              />
              <Button
                variant={onlineOnly ? "default" : "outline"}
                size="sm"
                onClick={() => setOnlineOnly((v) => !v)}
              >
                Online saja
              </Button>
            </div>
          </CardHeader>
          <CardContent className="overflow-x-auto">
            <table className="w-full min-w-[760px] text-sm">
              <thead>
                <tr className="border-b text-left text-muted-foreground">
                  <th className="py-2 pr-3">Status</th>
                  <th className="py-2 pr-3">Perangkat</th>
                  <th className="py-2 pr-3">Tenant / User</th>
                  <th className="py-2 pr-3">IP</th>
                  <th className="py-2 pr-3">Device ID</th>
                  <th className="py-2 pr-3">Terakhir</th>
                </tr>
              </thead>
              <tbody>
                {isLoading ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-muted-foreground">
                      Memuat...
                    </td>
                  </tr>
                ) : devices.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-muted-foreground">
                      Belum ada perangkat terdaftar. Login dari HP/Web untuk
                      mendaftarkan remote agent.
                    </td>
                  </tr>
                ) : (
                  devices.map((device) => (
                    <DeviceRow
                      key={device.id}
                      device={device}
                      selected={selectedId === device.id}
                      onSelect={() => setSelectedId(device.id)}
                    />
                  ))
                )}
              </tbody>
            </table>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Remote Control</CardTitle>
            <CardDescription>
              Pilih perangkat lalu kirim perintah diagnostik / perbaikan
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {!selectedId || !detail ? (
              <p className="text-sm text-muted-foreground">
                Pilih perangkat di tabel untuk akses remote.
              </p>
            ) : (
              <>
                <div className="rounded-lg border bg-slate-50 p-3 text-sm">
                  <p className="font-medium">{detail.device.device_name}</p>
                  <p className="text-muted-foreground">
                    {detail.device.platform} · v{detail.device.app_version}
                    {detail.device.build_number
                      ? ` (${detail.device.build_number})`
                      : ""}
                  </p>
                  <p className="mt-2">
                    <span className="text-muted-foreground">IP:</span>{" "}
                    {detail.device.last_ip ?? "-"}
                  </p>
                  <p>
                    <span className="text-muted-foreground">MAC / Device ID:</span>{" "}
                    {detail.device.mac_address ?? detail.device.fingerprint}
                  </p>
                  <p>
                    <span className="text-muted-foreground">Server API:</span>{" "}
                    {detail.device.api_base_url ?? "-"}
                  </p>
                  <p>
                    <span className="text-muted-foreground">User:</span>{" "}
                    {detail.device.user?.email ?? "-"}
                  </p>
                </div>

                <div className="grid grid-cols-2 gap-2">
                  {COMMANDS.map((cmd) => (
                    <Button
                      key={cmd.id}
                      size="sm"
                      variant="outline"
                      disabled={commandMutation.isPending}
                      onClick={() =>
                        commandMutation.mutate({
                          id: selectedId,
                          command: cmd.id,
                        })
                      }
                    >
                      <Terminal className="h-3.5 w-3.5" />
                      {cmd.label}
                    </Button>
                  ))}
                </div>

                <div>
                  <p className="mb-2 text-sm font-medium">Diagnostik Terbaru</p>
                  <div className="max-h-48 space-y-2 overflow-y-auto">
                    {detail.diagnostics.length === 0 ? (
                      <p className="text-xs text-muted-foreground">
                        Belum ada data diagnostik.
                      </p>
                    ) : (
                      detail.diagnostics.map((item) => (
                        <div
                          key={item.id}
                          className="rounded border bg-white p-2 text-xs"
                        >
                          <p className="font-medium">
                            {item.title ?? item.type} ·{" "}
                            {item.created_at
                              ? formatDate(item.created_at)
                              : "-"}
                          </p>
                          <pre className="mt-1 max-h-24 overflow-auto whitespace-pre-wrap text-[11px] text-muted-foreground">
                            {item.content}
                          </pre>
                        </div>
                      ))
                    )}
                  </div>
                </div>

                <div>
                  <p className="mb-2 text-sm font-medium">Riwayat Perintah</p>
                  <div className="max-h-36 space-y-2 overflow-y-auto">
                    {detail.commands.map((cmd) => (
                      <div
                        key={cmd.id}
                        className="rounded border bg-white p-2 text-xs"
                      >
                        <p>
                          <span className="font-medium">{cmd.command}</span> ·{" "}
                          {cmd.status}
                        </p>
                        {cmd.result && (
                          <p className="text-muted-foreground">{cmd.result}</p>
                        )}
                      </div>
                    ))}
                  </div>
                </div>

                {detail.device.platform === "android" && (
                  <div className="rounded-lg border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900">
                    <p className="font-medium">Akses penuh Android (ADB)</p>
                    <p className="mt-1">
                      Hubungkan USB/WiFi ADB lalu jalankan:{" "}
                      <code>adb devices</code> — fingerprint perangkat:{" "}
                      <code>{detail.device.fingerprint}</code>
                    </p>
                  </div>
                )}
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function DeviceRow({
  device,
  selected,
  onSelect,
}: {
  device: PlatformDevice;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <tr
      className={`cursor-pointer border-b transition-colors hover:bg-slate-50 ${
        selected ? "bg-primary/5" : ""
      }`}
      onClick={onSelect}
    >
      <td className="py-3 pr-3">
        <span
          className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium ${
            device.is_online
              ? "bg-emerald-100 text-emerald-700"
              : "bg-slate-100 text-slate-600"
          }`}
        >
          <Wifi className="h-3 w-3" />
          {device.is_online ? "Online" : "Offline"}
        </span>
      </td>
      <td className="py-3 pr-3">
        <p className="font-medium">{device.device_name}</p>
        <p className="text-xs text-muted-foreground">
          {device.platform}
          {device.app_version ? ` · v${device.app_version}` : ""}
        </p>
      </td>
      <td className="py-3 pr-3">
        <p>{device.tenant?.name ?? "-"}</p>
        <p className="text-xs text-muted-foreground">
          {device.user?.email ?? "-"}
        </p>
      </td>
      <td className="py-3 pr-3 font-mono text-xs">{device.last_ip ?? "-"}</td>
      <td className="py-3 pr-3 font-mono text-xs">
        {(device.mac_address ?? device.fingerprint).slice(0, 18)}
        {(device.mac_address ?? device.fingerprint).length > 18 ? "…" : ""}
      </td>
      <td className="py-3 pr-3 text-xs text-muted-foreground">
        {device.last_seen_at ? formatDate(device.last_seen_at) : "-"}
      </td>
    </tr>
  );
}