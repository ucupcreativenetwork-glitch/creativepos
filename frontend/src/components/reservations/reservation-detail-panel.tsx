"use client";

import { useEffect, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, UserCheck, UserX, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import {
  updateReservation,
  updateReservationStatus,
} from "@/lib/api/reservations";
import { getTables } from "@/lib/api/tables";
import { formatDate } from "@/lib/utils/format";
import { cn } from "@/lib/utils/cn";
import type { Reservation, ReservationStatus } from "@/types/reservation";

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

interface ReservationDetailPanelProps {
  reservation: Reservation | null;
  onClose: () => void;
  onRefresh: () => void;
}

export function ReservationDetailPanel({
  reservation,
  onClose,
  onRefresh,
}: ReservationDetailPanelProps) {
  const queryClient = useQueryClient();
  const [notes, setNotes] = useState("");
  const [tableId, setTableId] = useState<number | "">("");

  const { data: tables = [] } = useQuery({
    queryKey: ["tables", reservation?.outlet_id],
    queryFn: () => getTables({ outlet_id: reservation!.outlet_id }),
    enabled: !!reservation?.outlet_id,
  });

  useEffect(() => {
    if (!reservation) return;
    setNotes(reservation.notes ?? "");
    setTableId(reservation.table_id ?? "");
  }, [reservation]);

  const updateMutation = useMutation({
    mutationFn: () =>
      updateReservation(reservation!.uuid, {
        notes: notes || undefined,
        table_id: tableId ? Number(tableId) : undefined,
      }),
    onSuccess: () => {
      toast.success("Reservasi diperbarui");
      queryClient.invalidateQueries({ queryKey: ["reservations"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const statusMutation = useMutation({
    mutationFn: (status: string) =>
      updateReservationStatus(reservation!.uuid, status),
    onSuccess: () => {
      toast.success("Status reservasi diperbarui");
      queryClient.invalidateQueries({ queryKey: ["reservations"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!reservation) return null;

  const isTerminal = ["completed", "cancelled", "no_show"].includes(
    reservation.status
  );

  return (
    <div className="fixed inset-y-0 right-0 z-50 w-full max-w-md border-l border-border bg-white shadow-xl">
      <div className="flex h-full flex-col">
        <div className="flex items-start justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">
              {reservation.reservation_number}
            </h2>
            <span
              className={cn(
                "mt-1 inline-flex rounded-full px-2 py-0.5 text-xs font-medium",
                statusColors[reservation.status]
              )}
            >
              {statusLabels[reservation.status]}
            </span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1 hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="flex-1 space-y-5 overflow-y-auto p-6">
          <div>
            <p className="text-sm font-medium">Pelanggan</p>
            <p>{reservation.customer_name}</p>
            <p className="text-sm text-muted-foreground">
              {reservation.customer_phone}
            </p>
          </div>

          <div>
            <p className="text-sm font-medium">Jadwal</p>
            <p className="text-sm">
              {formatDate(reservation.reservation_date, {
                weekday: "long",
                day: "numeric",
                month: "long",
                year: "numeric",
              })}
            </p>
            <p className="text-sm text-muted-foreground">
              {reservation.reservation_time?.slice(0, 5)} ·{" "}
              {reservation.guest_count} tamu
            </p>
          </div>

          {reservation.outlet && (
            <div>
              <p className="text-sm font-medium">Outlet</p>
              <p className="text-sm text-muted-foreground">
                {reservation.outlet.name}
              </p>
            </div>
          )}

          {tables.length > 0 && (
            <div className="space-y-2">
              <Label>Meja</Label>
              <select
                value={tableId}
                onChange={(e) =>
                  setTableId(e.target.value ? Number(e.target.value) : "")
                }
                disabled={isTerminal}
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm disabled:opacity-50"
              >
                <option value="">Belum ditentukan</option>
                {tables.map((t) => (
                  <option key={t.id} value={t.id}>
                    Meja {t.table_number}
                    {t.name ? ` — ${t.name}` : ""} (kap. {t.capacity})
                  </option>
                ))}
              </select>
            </div>
          )}

          <div className="space-y-2">
            <Label>Catatan</Label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              disabled={isTerminal}
              rows={3}
              className="flex w-full rounded-lg border border-border bg-white px-3 py-2 text-sm disabled:opacity-50"
            />
          </div>

          {!isTerminal && (
            <Button
              variant="outline"
              className="w-full"
              onClick={() => updateMutation.mutate()}
              isLoading={updateMutation.isPending}
            >
              Simpan Perubahan
            </Button>
          )}
        </div>

        {!isTerminal && (
          <div className="space-y-2 border-t border-border p-6">
            {reservation.status === "pending" && (
              <Button
                className="w-full"
                onClick={() => statusMutation.mutate("confirmed")}
                isLoading={statusMutation.isPending}
              >
                <Check className="h-4 w-4" />
                Konfirmasi
              </Button>
            )}
            {reservation.status === "confirmed" && (
              <>
                <Button
                  className="w-full"
                  onClick={() => statusMutation.mutate("arrived")}
                  isLoading={statusMutation.isPending}
                >
                  <UserCheck className="h-4 w-4" />
                  Tamu Datang
                </Button>
                <Button
                  variant="outline"
                  className="w-full text-red-600"
                  onClick={() => statusMutation.mutate("no_show")}
                  isLoading={statusMutation.isPending}
                >
                  <UserX className="h-4 w-4" />
                  Tidak Hadir
                </Button>
              </>
            )}
            {reservation.status === "arrived" && (
              <Button
                className="w-full"
                onClick={() => statusMutation.mutate("completed")}
                isLoading={statusMutation.isPending}
              >
                <Check className="h-4 w-4" />
                Selesai
              </Button>
            )}
            <Button
              variant="ghost"
              className="w-full text-red-600"
              onClick={() => statusMutation.mutate("cancelled")}
              isLoading={statusMutation.isPending}
            >
              Batalkan Reservasi
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}