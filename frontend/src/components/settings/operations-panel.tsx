"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Calendar, Copy, Plus, QrCode, Trash2 } from "lucide-react";
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
  createTimeSlotConfig,
  deleteTimeSlotConfig,
  getTimeSlotConfigs,
} from "@/lib/api/reservations";
import {
  createTable,
  generateTableQr,
  getTables,
} from "@/lib/api/tables";
import { usePackageFeatures } from "@/hooks/usePackageFeatures";

const dayLabels = ["Min", "Sen", "Sel", "Rab", "Kam", "Jum", "Sab"];

export function OperationsPanel() {
  const queryClient = useQueryClient();
  const { hasFeature } = usePackageFeatures();
  const hasOrder = hasFeature("order");
  const hasReservation = hasFeature("reservation");

  const [outletId, setOutletId] = useState<number | "">("");

  const [tableNumber, setTableNumber] = useState("");
  const [tableName, setTableName] = useState("");
  const [tableCapacity, setTableCapacity] = useState("4");

  const [slotDay, setSlotDay] = useState(1);
  const [slotStart, setSlotStart] = useState("11:00");
  const [slotEnd, setSlotEnd] = useState("14:00");
  const [slotCapacity, setSlotCapacity] = useState("20");

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const selectedOutlet = outletId ? Number(outletId) : outlets[0]?.id;

  const { data: tables = [] } = useQuery({
    queryKey: ["tables", selectedOutlet],
    queryFn: () => getTables({ outlet_id: selectedOutlet }),
    enabled: hasOrder && !!selectedOutlet,
  });

  const { data: timeSlots = [] } = useQuery({
    queryKey: ["reservations", "time-slots", selectedOutlet],
    queryFn: () => getTimeSlotConfigs({ outlet_id: selectedOutlet }),
    enabled: hasReservation && !!selectedOutlet,
  });

  const tableMutation = useMutation({
    mutationFn: createTable,
    onSuccess: () => {
      toast.success("Meja ditambahkan");
      setTableNumber("");
      setTableName("");
      queryClient.invalidateQueries({ queryKey: ["tables"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const qrMutation = useMutation({
    mutationFn: generateTableQr,
    onSuccess: async (result) => {
      try {
        await navigator.clipboard.writeText(result.menu_url);
        toast.success("Link menu QR disalin ke clipboard");
      } catch {
        toast.success(`QR dibuat: ${result.menu_url}`);
      }
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const slotMutation = useMutation({
    mutationFn: createTimeSlotConfig,
    onSuccess: () => {
      toast.success("Slot waktu ditambahkan");
      queryClient.invalidateQueries({ queryKey: ["reservations", "time-slots"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const deleteSlotMutation = useMutation({
    mutationFn: deleteTimeSlotConfig,
    onSuccess: () => {
      toast.success("Slot dihapus");
      queryClient.invalidateQueries({ queryKey: ["reservations", "time-slots"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!hasOrder && !hasReservation) {
    return (
      <Card>
        <CardContent className="py-12 text-center text-muted-foreground">
          Fitur meja dan slot reservasi memerlukan paket Business atau Enterprise.
        </CardContent>
      </Card>
    );
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
        {hasOrder && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <QrCode className="h-4 w-4" />
                Meja & QR Menu
              </CardTitle>
              <CardDescription>
                Kelola meja dan generate link QR untuk pesanan mandiri
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-3 sm:grid-cols-3">
                <div className="space-y-2">
                  <Label>No. Meja</Label>
                  <Input
                    value={tableNumber}
                    onChange={(e) => setTableNumber(e.target.value)}
                    placeholder="A1"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Nama</Label>
                  <Input
                    value={tableName}
                    onChange={(e) => setTableName(e.target.value)}
                    placeholder="VIP"
                  />
                </div>
                <div className="space-y-2">
                  <Label>Kapasitas</Label>
                  <Input
                    type="number"
                    min={1}
                    value={tableCapacity}
                    onChange={(e) => setTableCapacity(e.target.value)}
                  />
                </div>
              </div>
              <Button
                onClick={() => {
                  if (!selectedOutlet || !tableNumber) {
                    toast.error("No. meja wajib diisi");
                    return;
                  }
                  tableMutation.mutate({
                    outlet_id: selectedOutlet,
                    table_number: tableNumber,
                    name: tableName || undefined,
                    capacity: Number(tableCapacity) || 4,
                  });
                }}
                isLoading={tableMutation.isPending}
              >
                <Plus className="h-4 w-4" />
                Tambah Meja
              </Button>

              {tables.length > 0 && (
                <div className="space-y-2 rounded-lg border border-border">
                  {tables.map((t) => (
                    <div
                      key={t.id}
                      className="flex items-center justify-between px-3 py-2 text-sm"
                    >
                      <div>
                        <span className="font-medium">Meja {t.table_number}</span>
                        {t.name && (
                          <span className="text-muted-foreground"> — {t.name}</span>
                        )}
                        <span className="ml-2 text-xs text-muted-foreground">
                          kap. {t.capacity}
                        </span>
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => qrMutation.mutate(t.id)}
                        isLoading={
                          qrMutation.isPending &&
                          qrMutation.variables === t.id
                        }
                      >
                        <Copy className="h-3.5 w-3.5" />
                        QR
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        )}

        {hasReservation && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <Calendar className="h-4 w-4" />
                Slot Waktu Reservasi
              </CardTitle>
              <CardDescription>
                Atur jadwal slot reservasi per hari
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-3 sm:grid-cols-2">
                <div className="space-y-2">
                  <Label>Hari</Label>
                  <select
                    value={slotDay}
                    onChange={(e) => setSlotDay(Number(e.target.value))}
                    className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
                  >
                    {dayLabels.map((label, i) => (
                      <option key={i} value={i}>
                        {label}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="space-y-2">
                  <Label>Kapasitas</Label>
                  <Input
                    type="number"
                    min={1}
                    value={slotCapacity}
                    onChange={(e) => setSlotCapacity(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Mulai</Label>
                  <Input
                    type="time"
                    value={slotStart}
                    onChange={(e) => setSlotStart(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label>Selesai</Label>
                  <Input
                    type="time"
                    value={slotEnd}
                    onChange={(e) => setSlotEnd(e.target.value)}
                  />
                </div>
              </div>
              <Button
                onClick={() => {
                  if (!selectedOutlet) return;
                  slotMutation.mutate({
                    outlet_id: selectedOutlet,
                    day_of_week: slotDay,
                    start_time: slotStart,
                    end_time: slotEnd,
                    capacity: Number(slotCapacity) || 10,
                  });
                }}
                isLoading={slotMutation.isPending}
              >
                <Plus className="h-4 w-4" />
                Tambah Slot
              </Button>

              {timeSlots.length > 0 && (
                <div className="space-y-2 rounded-lg border border-border">
                  {timeSlots.map((s) => (
                    <div
                      key={s.id}
                      className="flex items-center justify-between px-3 py-2 text-sm"
                    >
                      <span>
                        {dayLabels[s.day_of_week]} {s.start_time}–{s.end_time}
                        <span className="ml-2 text-xs text-muted-foreground">
                          kap. {s.capacity}
                        </span>
                      </span>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-red-600"
                        onClick={() => deleteSlotMutation.mutate(s.id)}
                        isLoading={
                          deleteSlotMutation.isPending &&
                          deleteSlotMutation.variables === s.id
                        }
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  );
}