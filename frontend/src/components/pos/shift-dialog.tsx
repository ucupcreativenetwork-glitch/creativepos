"use client";

import { useEffect, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import { closeShift, openShift } from "@/lib/api/pos";
import type { Shift } from "@/types/pos";

interface ShiftDialogProps {
  open: boolean;
  mode: "open" | "close";
  outletId: number;
  shift?: Shift | null;
  onClose: () => void;
  onSuccess: () => void;
}

export function ShiftDialog({
  open,
  mode,
  outletId,
  shift,
  onClose,
  onSuccess,
}: ShiftDialogProps) {
  const [cash, setCash] = useState("0");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    if (!open) return;
    setCash("0");
    setNotes("");
  }, [open, mode]);

  const openMutation = useMutation({
    mutationFn: () => openShift(outletId, Number(cash)),
    onSuccess: () => {
      toast.success("Shift berhasil dibuka");
      onSuccess();
      onClose();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const closeMutation = useMutation({
    mutationFn: () => closeShift(shift!.id, Number(cash), notes || undefined),
    onSuccess: () => {
      toast.success("Shift berhasil ditutup");
      onSuccess();
      onClose();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!open) return null;

  const cashNum = Number(cash);
  const cashInvalid = !Number.isFinite(cashNum) || cashNum < 0;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <h2 className="text-lg font-semibold">
            {mode === "open" ? "Buka Shift" : "Tutup Shift"}
          </h2>
          <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 p-6">
          {mode === "close" && shift && (
            <div className="rounded-lg bg-slate-50 p-3 text-sm">
              <p>Total penjualan: <strong>{shift.total_transactions} transaksi</strong></p>
              <p>Nilai penjualan: <strong>Rp {shift.total_sales.toLocaleString("id-ID")}</strong></p>
            </div>
          )}

          <div className="space-y-2">
            <Label>
              {mode === "open" ? "Kas Awal" : "Kas Akhir"}
            </Label>
            <Input
              type="number"
              value={cash}
              onChange={(e) => setCash(e.target.value)}
              min={0}
            />
          </div>

          {mode === "close" && (
            <div className="space-y-2">
              <Label>Catatan</Label>
              <Input
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Opsional"
              />
            </div>
          )}

          <div className="flex justify-end gap-3">
            <Button variant="outline" onClick={onClose}>Batal</Button>
            <Button
              onClick={() =>
                mode === "open"
                  ? openMutation.mutate()
                  : closeMutation.mutate()
              }
              isLoading={openMutation.isPending || closeMutation.isPending}
              disabled={cashInvalid}
            >
              {mode === "open" ? "Buka Shift" : "Tutup Shift"}
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}