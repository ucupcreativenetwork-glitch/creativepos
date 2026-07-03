"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  CalendarDays,
  Check,
  ChevronLeft,
  ChevronRight,
  Plus,
  UserCheck,
  X,
} from "lucide-react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
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
import { getErrorMessage, getFieldErrors } from "@/lib/api/client";
import { ReservationDetailPanel } from "@/components/reservations/reservation-detail-panel";
import {
  createReservation,
  getReservationCalendar,
  getReservationSlots,
  getReservations,
  updateReservationStatus,
} from "@/lib/api/reservations";
import { cn } from "@/lib/utils/cn";
import { formatDate } from "@/lib/utils/format";
import type { Reservation, ReservationStatus } from "@/types/reservation";

const reservationSchema = z.object({
  outlet_id: z.number().min(1, "Outlet wajib dipilih"),
  customer_name: z.string().min(1, "Nama wajib diisi"),
  customer_phone: z
    .string()
    .min(1, "Nomor telepon wajib diisi")
    .regex(/^08\d{8,12}$/, "Format: 08xxxxxxxxxx"),
  guest_count: z.number().min(1, "Minimal 1 tamu").max(50),
  reservation_date: z.string().min(1, "Tanggal wajib diisi"),
  reservation_time: z.string().min(1, "Slot waktu wajib dipilih"),
  notes: z.string().optional(),
});

type ReservationForm = z.infer<typeof reservationSchema>;

const statusLabels: Record<ReservationStatus, string> = {
  pending: "Menunggu",
  confirmed: "Dikonfirmasi",
  arrived: "Sudah Datang",
  completed: "Selesai",
  cancelled: "Dibatalkan",
  no_show: "Tidak Hadir",
};

const statusColors: Record<ReservationStatus, string> = {
  pending: "bg-amber-50 text-amber-700",
  confirmed: "bg-blue-50 text-blue-700",
  arrived: "bg-violet-50 text-violet-700",
  completed: "bg-emerald-50 text-emerald-700",
  cancelled: "bg-slate-100 text-slate-600",
  no_show: "bg-red-50 text-red-700",
};

function formatTime(time: string): string {
  if (!time) return "—";
  const parts = time.split(":");
  return `${parts[0]}:${parts[1]}`;
}

function toDateString(date: Date): string {
  return date.toISOString().split("T")[0];
}

function getWeekRange(baseDate: Date): { from: string; to: string; days: Date[] } {
  const start = new Date(baseDate);
  const day = start.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  start.setDate(start.getDate() + diff);

  const days: Date[] = [];
  for (let i = 0; i < 7; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    days.push(d);
  }

  return {
    from: toDateString(days[0]),
    to: toDateString(days[6]),
    days,
  };
}

function ReservationFormDialog({
  open,
  onClose,
  onSuccess,
  defaultOutletId,
}: {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  defaultOutletId?: number;
}) {
  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const {
    register,
    handleSubmit,
    watch,
    reset,
    setError,
    setValue,
    formState: { errors },
  } = useForm<ReservationForm>({
    resolver: zodResolver(reservationSchema),
    defaultValues: {
      outlet_id: defaultOutletId ?? 0,
      guest_count: 2,
      reservation_date: toDateString(new Date()),
      reservation_time: "",
      notes: "",
    },
  });

  const outletId = watch("outlet_id");
  const reservationDate = watch("reservation_date");
  const guestCount = watch("guest_count");

  const { data: slots = [], isLoading: slotsLoading } = useQuery({
    queryKey: ["reservations", "slots", outletId, reservationDate, guestCount],
    queryFn: () =>
      getReservationSlots({
        outlet_id: Number(outletId),
        date: reservationDate,
        guest_count: Number(guestCount),
      }),
    enabled: open && !!outletId && !!reservationDate,
  });

  const mutation = useMutation({
    mutationFn: createReservation,
    onSuccess: () => {
      toast.success("Reservasi berhasil dibuat");
      reset();
      onSuccess();
      onClose();
    },
    onError: (error) => {
      const fieldErrors = getFieldErrors(error);
      Object.entries(fieldErrors).forEach(([field, message]) => {
        setError(field as keyof ReservationForm, { message });
      });
      toast.error(getErrorMessage(error));
    },
  });

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="max-h-[90vh] w-full max-w-md overflow-y-auto rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold">Buat Reservasi</h2>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1 hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <form
          onSubmit={handleSubmit((v) => mutation.mutate(v))}
          className="space-y-4 p-6"
        >
          <div className="space-y-2">
            <Label htmlFor="outlet_id">Outlet</Label>
            <select
              id="outlet_id"
              value={outletId || 0}
              className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              onChange={(e) => {
                setValue("outlet_id", Number(e.target.value), {
                  shouldValidate: true,
                });
                setValue("reservation_time", "");
              }}
            >
              <option value={0}>Pilih outlet</option>
              {outlets.map((o) => (
                <option key={o.id} value={o.id}>
                  {o.name}
                </option>
              ))}
            </select>
            {errors.outlet_id && (
              <p className="text-xs text-red-600">{errors.outlet_id.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="customer_name">Nama Pelanggan</Label>
            <Input id="customer_name" {...register("customer_name")} />
            {errors.customer_name && (
              <p className="text-xs text-red-600">{errors.customer_name.message}</p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="customer_phone">Telepon</Label>
            <Input
              id="customer_phone"
              {...register("customer_phone")}
              placeholder="08xxxxxxxxxx"
            />
            {errors.customer_phone && (
              <p className="text-xs text-red-600">{errors.customer_phone.message}</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-2">
              <Label htmlFor="guest_count">Jumlah Tamu</Label>
              <Input
                id="guest_count"
                type="number"
                min={1}
                {...register("guest_count", { valueAsNumber: true })}
              />
              {errors.guest_count && (
                <p className="text-xs text-red-600">{errors.guest_count.message}</p>
              )}
            </div>
            <div className="space-y-2">
              <Label htmlFor="reservation_date">Tanggal</Label>
              <Input
                id="reservation_date"
                type="date"
                {...register("reservation_date")}
                onChange={(e) => {
                  setValue("reservation_date", e.target.value);
                  setValue("reservation_time", "");
                }}
              />
              {errors.reservation_date && (
                <p className="text-xs text-red-600">
                  {errors.reservation_date.message}
                </p>
              )}
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="reservation_time">Slot Waktu</Label>
            {slotsLoading ? (
              <p className="text-sm text-muted-foreground">Memuat slot...</p>
            ) : slots.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Tidak ada slot tersedia
              </p>
            ) : (
              <select
                id="reservation_time"
                {...register("reservation_time")}
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="">Pilih waktu</option>
                {slots.map((slot) => (
                  <option
                    key={slot.time}
                    value={slot.time}
                    disabled={!slot.available}
                  >
                    {formatTime(slot.time)}
                    {!slot.available
                      ? " (Penuh)"
                      : ` (${slot.booked_count}/${slot.capacity})`}
                  </option>
                ))}
              </select>
            )}
            {errors.reservation_time && (
              <p className="text-xs text-red-600">
                {errors.reservation_time.message}
              </p>
            )}
          </div>

          <div className="space-y-2">
            <Label htmlFor="notes">Catatan</Label>
            <textarea
              id="notes"
              {...register("notes")}
              rows={2}
              className="flex w-full rounded-lg border border-border bg-white px-3 py-2 text-sm"
              placeholder="Permintaan khusus, alergi, dll."
            />
          </div>

          <div className="flex justify-end gap-3">
            <Button type="button" variant="outline" onClick={onClose}>
              Batal
            </Button>
            <Button type="submit" isLoading={mutation.isPending}>
              Simpan
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default function ReservationsPage() {
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<"list" | "calendar">("list");
  const [formOpen, setFormOpen] = useState(false);
  const [page, setPage] = useState(1);
  const [outletFilter, setOutletFilter] = useState<number | "">("");
  const [statusFilter, setStatusFilter] = useState("");
  const [dateFilter, setDateFilter] = useState("");
  const [weekStart, setWeekStart] = useState(new Date());
  const [selectedReservation, setSelectedReservation] =
    useState<Reservation | null>(null);

  const { data: outlets = [] } = useQuery({
    queryKey: ["dashboard", "outlets"],
    queryFn: getOutlets,
    staleTime: 5 * 60 * 1000,
  });

  const weekRange = useMemo(() => getWeekRange(weekStart), [weekStart]);

  const { data: listData, isLoading: listLoading, refetch } = useQuery({
    queryKey: [
      "reservations",
      "list",
      outletFilter,
      statusFilter,
      dateFilter,
      page,
    ],
    queryFn: () =>
      getReservations({
        outlet_id: outletFilter ? Number(outletFilter) : undefined,
        status: statusFilter || undefined,
        date: dateFilter || undefined,
        page,
        per_page: 10,
      }),
    enabled: tab === "list",
    staleTime: 30 * 1000,
  });

  const { data: calendarDays = [], isLoading: calendarLoading } = useQuery({
    queryKey: [
      "reservations",
      "calendar",
      outletFilter,
      weekRange.from,
      weekRange.to,
    ],
    queryFn: () =>
      getReservationCalendar({
        outlet_id: outletFilter ? Number(outletFilter) : undefined,
        date_from: weekRange.from,
        date_to: weekRange.to,
      }),
    enabled: tab === "calendar",
    staleTime: 30 * 1000,
  });

  const statusMutation = useMutation({
    mutationFn: ({ uuid, status }: { uuid: string; status: string }) =>
      updateReservationStatus(uuid, status),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["reservations"] });
      toast.success("Status reservasi diperbarui");
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const reservations = listData?.data ?? [];
  const meta = listData?.meta;

  const calendarMap = useMemo(() => {
    const map = new Map<string, (typeof calendarDays)[0]>();
    for (const day of calendarDays) {
      map.set(day.date, day);
    }
    return map;
  }, [calendarDays]);

  const defaultOutletId = outletFilter
    ? Number(outletFilter)
    : outlets[0]?.id;

  function handleQuickAction(reservation: Reservation, action: string) {
    statusMutation.mutate({ uuid: reservation.uuid, status: action });
  }

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="flex items-center gap-2 text-2xl font-bold tracking-tight">
            <CalendarDays className="h-7 w-7 text-primary" />
            Reservasi
          </h1>
          <p className="mt-1 text-muted-foreground">
            Kelola reservasi meja dan kalender mingguan
          </p>
        </div>
        <Button onClick={() => setFormOpen(true)}>
          <Plus className="h-4 w-4" />
          Buat Reservasi
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <div className="flex rounded-lg border border-border bg-white p-1">
          <button
            type="button"
            onClick={() => setTab("list")}
            className={cn(
              "rounded-md px-4 py-1.5 text-sm font-medium transition-colors",
              tab === "list"
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:text-foreground"
            )}
          >
            Daftar
          </button>
          <button
            type="button"
            onClick={() => setTab("calendar")}
            className={cn(
              "rounded-md px-4 py-1.5 text-sm font-medium transition-colors",
              tab === "calendar"
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:text-foreground"
            )}
          >
            Kalender
          </button>
        </div>

        <select
          value={outletFilter}
          onChange={(e) => {
            setOutletFilter(e.target.value ? Number(e.target.value) : "");
            setPage(1);
          }}
          className="h-10 rounded-lg border border-border bg-white px-3 text-sm"
        >
          <option value="">Semua Outlet</option>
          {outlets.map((o) => (
            <option key={o.id} value={o.id}>
              {o.name}
            </option>
          ))}
        </select>

        {tab === "list" && (
          <>
            <select
              value={statusFilter}
              onChange={(e) => {
                setStatusFilter(e.target.value);
                setPage(1);
              }}
              className="h-10 rounded-lg border border-border bg-white px-3 text-sm"
            >
              <option value="">Semua Status</option>
              {Object.entries(statusLabels).map(([value, label]) => (
                <option key={value} value={value}>
                  {label}
                </option>
              ))}
            </select>
            <Input
              type="date"
              value={dateFilter}
              onChange={(e) => {
                setDateFilter(e.target.value);
                setPage(1);
              }}
              className="w-auto"
            />
          </>
        )}
      </div>

      {tab === "list" ? (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Daftar Reservasi</CardTitle>
            <CardDescription>
              {meta ? `${meta.total} reservasi` : "Memuat..."}
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {listLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-14 animate-pulse rounded-lg bg-slate-100"
                  />
                ))}
              </div>
            ) : reservations.length === 0 ? (
              <div className="flex flex-col items-center py-12 text-center">
                <CalendarDays className="mb-3 h-10 w-10 text-muted-foreground" />
                <p className="font-medium">Belum ada reservasi</p>
              </div>
            ) : (
              <div className="overflow-x-auto rounded-lg border border-border">
                <table className="w-full text-sm">
                  <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                    <tr>
                      <th className="px-4 py-3 font-medium">No. Reservasi</th>
                      <th className="px-4 py-3 font-medium">Pelanggan</th>
                      <th className="px-4 py-3 font-medium">Tanggal & Waktu</th>
                      <th className="px-4 py-3 font-medium text-center">Tamu</th>
                      <th className="px-4 py-3 font-medium">Status</th>
                      <th className="px-4 py-3 font-medium text-right">Aksi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border">
                    {reservations.map((reservation) => (
                      <tr
                        key={reservation.uuid}
                        className="cursor-pointer hover:bg-slate-50/50"
                        onClick={() => setSelectedReservation(reservation)}
                      >
                        <td className="px-4 py-3 font-medium">
                          {reservation.reservation_number}
                        </td>
                        <td className="px-4 py-3">
                          <p className="font-medium">{reservation.customer_name}</p>
                          <p className="text-xs text-muted-foreground">
                            {reservation.customer_phone}
                          </p>
                        </td>
                        <td className="px-4 py-3">
                          {formatDate(reservation.reservation_date, {
                            day: "numeric",
                            month: "short",
                            year: "numeric",
                          })}
                          {" · "}
                          {formatTime(reservation.reservation_time)}
                        </td>
                        <td className="px-4 py-3 text-center">
                          {reservation.guest_count}
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={cn(
                              "inline-flex rounded-full px-2 py-0.5 text-xs font-medium",
                              statusColors[reservation.status]
                            )}
                          >
                            {statusLabels[reservation.status]}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex justify-end gap-1">
                            {reservation.status === "pending" && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleQuickAction(reservation, "confirmed");
                                }}
                                isLoading={
                                  statusMutation.isPending &&
                                  statusMutation.variables?.uuid ===
                                    reservation.uuid
                                }
                              >
                                <Check className="h-3.5 w-3.5" />
                                Konfirmasi
                              </Button>
                            )}
                            {reservation.status === "confirmed" && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleQuickAction(reservation, "arrived");
                                }}
                                isLoading={
                                  statusMutation.isPending &&
                                  statusMutation.variables?.uuid ===
                                    reservation.uuid
                                }
                              >
                                <UserCheck className="h-3.5 w-3.5" />
                                Datang
                              </Button>
                            )}
                            {reservation.status === "arrived" && (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleQuickAction(reservation, "completed");
                                }}
                                isLoading={
                                  statusMutation.isPending &&
                                  statusMutation.variables?.uuid ===
                                    reservation.uuid
                                }
                              >
                                <Check className="h-3.5 w-3.5" />
                                Selesai
                              </Button>
                            )}
                            {!["completed", "cancelled", "no_show"].includes(
                              reservation.status
                            ) && (
                              <Button
                                size="sm"
                                variant="ghost"
                                className="text-red-600 hover:text-red-700"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  handleQuickAction(reservation, "cancelled");
                                }}
                                isLoading={
                                  statusMutation.isPending &&
                                  statusMutation.variables?.uuid ===
                                    reservation.uuid
                                }
                              >
                                <X className="h-3.5 w-3.5" />
                                Batal
                              </Button>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {meta && meta.last_page > 1 && (
              <div className="flex items-center justify-between">
                <p className="text-sm text-muted-foreground">
                  Halaman {meta.current_page} dari {meta.last_page}
                </p>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={page <= 1}
                    onClick={() => setPage((p) => p - 1)}
                  >
                    Sebelumnya
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={page >= meta.last_page}
                    onClick={() => setPage((p) => p + 1)}
                  >
                    Berikutnya
                  </Button>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      ) : (
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-base">Kalender Mingguan</CardTitle>
                <CardDescription>
                  {formatDate(weekRange.from, {
                    day: "numeric",
                    month: "long",
                  })}
                  {" — "}
                  {formatDate(weekRange.to, {
                    day: "numeric",
                    month: "long",
                    year: "numeric",
                  })}
                </CardDescription>
              </div>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    const prev = new Date(weekStart);
                    prev.setDate(prev.getDate() - 7);
                    setWeekStart(prev);
                  }}
                >
                  <ChevronLeft className="h-4 w-4" />
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setWeekStart(new Date())}
                >
                  Hari Ini
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    const next = new Date(weekStart);
                    next.setDate(next.getDate() + 7);
                    setWeekStart(next);
                  }}
                >
                  <ChevronRight className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            {calendarLoading ? (
              <div className="grid gap-3 sm:grid-cols-7">
                {Array.from({ length: 7 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-32 animate-pulse rounded-lg bg-slate-100"
                  />
                ))}
              </div>
            ) : (
              <div className="grid gap-3 sm:grid-cols-7">
                {weekRange.days.map((day) => {
                  const dateStr = toDateString(day);
                  const dayData = calendarMap.get(dateStr);
                  const count = dayData?.count ?? 0;
                  const isToday = dateStr === toDateString(new Date());

                  return (
                    <div
                      key={dateStr}
                      className={cn(
                        "rounded-lg border p-3",
                        isToday
                          ? "border-primary bg-primary/5"
                          : "border-border bg-white"
                      )}
                    >
                      <div className="mb-2 flex items-center justify-between">
                        <p className="text-xs font-medium text-muted-foreground">
                          {formatDate(day, { weekday: "short" })}
                        </p>
                        <span
                          className={cn(
                            "rounded-full px-2 py-0.5 text-xs font-bold",
                            count > 0
                              ? "bg-primary/10 text-primary"
                              : "bg-slate-100 text-muted-foreground"
                          )}
                        >
                          {count}
                        </span>
                      </div>
                      <p className="text-lg font-semibold">{day.getDate()}</p>
                      {dayData?.reservations && dayData.reservations.length > 0 && (
                        <ul className="mt-2 space-y-1">
                          {dayData.reservations.slice(0, 3).map((r) => (
                            <li
                              key={r.uuid}
                              className="truncate text-[10px] text-muted-foreground"
                            >
                              {formatTime(r.reservation_time)} · {r.customer_name}
                            </li>
                          ))}
                          {dayData.reservations.length > 3 && (
                            <li className="text-[10px] text-muted-foreground">
                              +{dayData.reservations.length - 3} lainnya
                            </li>
                          )}
                        </ul>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      <ReservationFormDialog
        open={formOpen}
        onClose={() => setFormOpen(false)}
        onSuccess={() => refetch()}
        defaultOutletId={defaultOutletId}
      />

      <ReservationDetailPanel
        reservation={selectedReservation}
        onClose={() => setSelectedReservation(null)}
        onRefresh={() => refetch()}
      />
    </div>
  );
}