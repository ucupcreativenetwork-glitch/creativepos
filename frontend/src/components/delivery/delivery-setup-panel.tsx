"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { MapPin, Plus, Truck, UserPlus } from "lucide-react";
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
import { getOutlets } from "@/lib/api/dashboard";
import { getErrorMessage } from "@/lib/api/client";
import {
  createDeliveryDriver,
  createDeliveryZone,
  getDrivers,
  getZones,
} from "@/lib/api/delivery";
import { getSettingsUsers } from "@/lib/api/settings";
import { formatCurrency } from "@/lib/utils/format";

export function DeliverySetupPanel() {
  const queryClient = useQueryClient();
  const [outletId, setOutletId] = useState<number | "">("");

  const [zoneName, setZoneName] = useState("");
  const [zoneCode, setZoneCode] = useState("");
  const [baseFee, setBaseFee] = useState("10000");
  const [feePerKm, setFeePerKm] = useState("2000");
  const [maxDistance, setMaxDistance] = useState("15");

  const [driverUserId, setDriverUserId] = useState<number | "">("");
  const [vehicleType, setVehicleType] = useState("motor");
  const [vehiclePlate, setVehiclePlate] = useState("");

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const selectedOutlet = outletId ? Number(outletId) : outlets[0]?.id;

  const { data: zones = [] } = useQuery({
    queryKey: ["delivery", "zones", selectedOutlet],
    queryFn: () => getZones({ outlet_id: selectedOutlet }),
    enabled: !!selectedOutlet,
  });

  const { data: drivers = [] } = useQuery({
    queryKey: ["delivery", "drivers", selectedOutlet],
    queryFn: () => getDrivers(),
    enabled: !!selectedOutlet,
  });

  const { data: usersData } = useQuery({
    queryKey: ["settings", "users", "delivery-setup"],
    queryFn: () => getSettingsUsers({ per_page: 50 }),
    staleTime: 60 * 1000,
  });

  const zoneMutation = useMutation({
    mutationFn: createDeliveryZone,
    onSuccess: () => {
      toast.success("Zona delivery ditambahkan");
      setZoneName("");
      setZoneCode("");
      queryClient.invalidateQueries({ queryKey: ["delivery", "zones"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const driverMutation = useMutation({
    mutationFn: createDeliveryDriver,
    onSuccess: () => {
      toast.success("Driver ditambahkan");
      setDriverUserId("");
      setVehiclePlate("");
      queryClient.invalidateQueries({ queryKey: ["delivery", "drivers"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  function handleCreateZone() {
    if (!selectedOutlet) {
      toast.error("Pilih outlet terlebih dahulu");
      return;
    }
    if (!zoneName || !zoneCode) {
      toast.error("Nama dan kode zona wajib diisi");
      return;
    }

    zoneMutation.mutate({
      outlet_id: selectedOutlet,
      name: zoneName,
      code: zoneCode,
      base_fee: Number(baseFee) || 0,
      fee_per_km: Number(feePerKm) || 0,
      max_distance_km: Number(maxDistance) || 15,
    });
  }

  function handleCreateDriver() {
    if (!driverUserId) {
      toast.error("Pilih pengguna untuk driver");
      return;
    }

    driverMutation.mutate({
      user_id: Number(driverUserId),
      outlet_id: selectedOutlet,
      vehicle_type: vehicleType,
      vehicle_plate: vehiclePlate || undefined,
    });
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center gap-3">
        <Label className="text-sm text-muted-foreground">Outlet:</Label>
        <select
          value={outletId || selectedOutlet || ""}
          onChange={(e) => setOutletId(Number(e.target.value))}
          className="h-10 rounded-lg border border-border bg-white px-3 text-sm"
        >
          {outlets.map((o) => (
            <option key={o.id} value={o.id}>
              {o.name}
            </option>
          ))}
        </select>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <MapPin className="h-4 w-4" />
              Zona Pengantaran
            </CardTitle>
            <CardDescription>
              Atur zona dan tarif ongkir per outlet
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-2">
                <Label>Nama Zona</Label>
                <Input
                  value={zoneName}
                  onChange={(e) => setZoneName(e.target.value)}
                  placeholder="Contoh: Radius 5km"
                />
              </div>
              <div className="space-y-2">
                <Label>Kode</Label>
                <Input
                  value={zoneCode}
                  onChange={(e) => setZoneCode(e.target.value.toUpperCase())}
                  placeholder="Z1"
                />
              </div>
              <div className="space-y-2">
                <Label>Tarif Dasar (Rp)</Label>
                <Input
                  type="number"
                  value={baseFee}
                  onChange={(e) => setBaseFee(e.target.value)}
                />
              </div>
              <div className="space-y-2">
                <Label>Tarif per km (Rp)</Label>
                <Input
                  type="number"
                  value={feePerKm}
                  onChange={(e) => setFeePerKm(e.target.value)}
                />
              </div>
            </div>
            <Button
              onClick={handleCreateZone}
              isLoading={zoneMutation.isPending}
            >
              <Plus className="h-4 w-4" />
              Tambah Zona
            </Button>

            {zones.length > 0 && (
              <div className="space-y-2 rounded-lg border border-border p-3">
                <p className="text-sm font-medium">Zona Aktif</p>
                {zones.map((z) => (
                  <div
                    key={z.id}
                    className="flex justify-between text-sm"
                  >
                    <span>{z.name}</span>
                    <span className="text-muted-foreground">
                      {formatCurrency(z.base_fee)}
                      {z.fee_per_km ? ` + ${formatCurrency(z.fee_per_km)}/km` : ""}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Truck className="h-4 w-4" />
              Driver
            </CardTitle>
            <CardDescription>
              Daftarkan staff sebagai driver pengantaran
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Pengguna</Label>
              <select
                value={driverUserId}
                onChange={(e) =>
                  setDriverUserId(e.target.value ? Number(e.target.value) : "")
                }
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="">Pilih staff</option>
                {(usersData?.data ?? []).map((u) => (
                  <option key={u.id} value={u.id}>
                    {u.name} ({u.email})
                  </option>
                ))}
              </select>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <div className="space-y-2">
                <Label>Kendaraan</Label>
                <select
                  value={vehicleType}
                  onChange={(e) => setVehicleType(e.target.value)}
                  className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
                >
                  <option value="motor">Motor</option>
                  <option value="mobil">Mobil</option>
                  <option value="sepeda">Sepeda</option>
                </select>
              </div>
              <div className="space-y-2">
                <Label>Plat Nomor</Label>
                <Input
                  value={vehiclePlate}
                  onChange={(e) => setVehiclePlate(e.target.value)}
                  placeholder="B 1234 XYZ"
                />
              </div>
            </div>
            <Button
              onClick={handleCreateDriver}
              isLoading={driverMutation.isPending}
            >
              <UserPlus className="h-4 w-4" />
              Tambah Driver
            </Button>

            {drivers.length > 0 && (
              <div className="space-y-2 rounded-lg border border-border p-3">
                <p className="text-sm font-medium">Driver Terdaftar</p>
                {drivers.map((d) => (
                  <div
                    key={d.id}
                    className="flex items-center justify-between text-sm"
                  >
                    <span>
                      {d.name}
                      {d.vehicle_type ? ` · ${d.vehicle_type}` : ""}
                    </span>
                    <span
                      className={
                        d.is_available
                          ? "text-emerald-600"
                          : "text-muted-foreground"
                      }
                    >
                      {d.is_available ? "Tersedia" : "Sibuk"}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}