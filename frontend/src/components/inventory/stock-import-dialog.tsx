"use client";

import { useRef, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Download, FileSpreadsheet, Upload, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import { importStock } from "@/lib/api/inventory";
import type { StockImportResult, Warehouse } from "@/types/inventory";

interface StockImportDialogProps {
  open: boolean;
  warehouses: Warehouse[];
  onClose: () => void;
  onSuccess: () => void;
}

const TEMPLATE_URL = "/templates/stock-import.csv";

export function StockImportDialog({
  open,
  warehouses,
  onClose,
  onSuccess,
}: StockImportDialogProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [warehouseId, setWarehouseId] = useState("");
  const [result, setResult] = useState<StockImportResult | null>(null);

  const mutation = useMutation({
    mutationFn: () => {
      if (!selectedFile) {
        throw new Error("Pilih file CSV atau Excel terlebih dahulu.");
      }

      return importStock(
        selectedFile,
        warehouseId ? Number(warehouseId) : undefined,
      );
    },
    onSuccess: (data) => {
      setResult(data);
      toast.success(
        `Import selesai: ${data.processed} berhasil, ${data.skipped} dilewati.`,
      );
      if (data.processed > 0) {
        onSuccess();
      }
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const handleClose = () => {
    setSelectedFile(null);
    setWarehouseId("");
    setResult(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = "";
    }
    onClose();
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-border px-6 py-4">
          <div>
            <h2 className="text-lg font-semibold">Import Stok Massal</h2>
            <p className="text-sm text-muted-foreground">
              Upload CSV atau Excel untuk update stok banyak produk sekaligus
            </p>
          </div>
          <button
            type="button"
            onClick={handleClose}
            className="rounded-lg p-1 text-muted-foreground hover:bg-slate-100"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="space-y-4 p-6">
          <div className="rounded-lg border border-dashed border-border bg-slate-50/80 p-4 text-sm">
            <p className="font-medium">Format kolom wajib:</p>
            <p className="mt-1 text-muted-foreground">
              <code>sku</code>, <code>quantity</code>, <code>action</code>{" "}
              (<code>in</code> / <code>out</code> / <code>adjustment</code>)
            </p>
            <p className="mt-2 text-muted-foreground">
              Opsional: <code>notes</code>, <code>warehouse_code</code>
            </p>
            <a
              href={TEMPLATE_URL}
              download
              className="mt-3 inline-flex items-center gap-2 text-sm font-medium text-primary hover:underline"
            >
              <Download className="h-4 w-4" />
              Unduh template CSV
            </a>
          </div>

          {warehouses.length > 0 && (
            <div className="space-y-2">
              <Label htmlFor="import_warehouse_id">Gudang default</Label>
              <select
                id="import_warehouse_id"
                value={warehouseId}
                onChange={(e) => setWarehouseId(e.target.value)}
                className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="">Gudang pertama aktif</option>
                {warehouses.map((warehouse) => (
                  <option key={warehouse.id} value={warehouse.id}>
                    {warehouse.name} ({warehouse.code})
                  </option>
                ))}
              </select>
              <p className="text-xs text-muted-foreground">
                Dipakai jika kolom <code>warehouse_code</code> kosong di file.
              </p>
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="stock_import_file">File CSV / Excel</Label>
            <div className="flex items-center gap-3">
              <input
                ref={fileInputRef}
                id="stock_import_file"
                type="file"
                accept=".csv,.txt,.xlsx,.xls"
                className="hidden"
                onChange={(event) => {
                  setSelectedFile(event.target.files?.[0] ?? null);
                  setResult(null);
                }}
              />
              <Button
                type="button"
                variant="outline"
                onClick={() => fileInputRef.current?.click()}
              >
                <Upload className="h-4 w-4" />
                Pilih File
              </Button>
              <span className="truncate text-sm text-muted-foreground">
                {selectedFile?.name ?? "Belum ada file dipilih"}
              </span>
            </div>
          </div>

          {result && (
            <div className="rounded-lg border border-border bg-slate-50 p-4 text-sm">
              <div className="flex items-center gap-2 font-medium">
                <FileSpreadsheet className="h-4 w-4" />
                Hasil import
              </div>
              <p className="mt-2">
                Berhasil: <strong>{result.processed}</strong> · Dilewati:{" "}
                <strong>{result.skipped}</strong>
              </p>
              {result.errors.length > 0 && (
                <ul className="mt-2 max-h-32 space-y-1 overflow-y-auto text-xs text-red-700">
                  {result.errors.slice(0, 10).map((error) => (
                    <li key={error}>• {error}</li>
                  ))}
                  {result.errors.length > 10 && (
                    <li>• ...dan {result.errors.length - 10} error lainnya</li>
                  )}
                </ul>
              )}
            </div>
          )}

          <div className="flex justify-end gap-3">
            <Button type="button" variant="outline" onClick={handleClose}>
              Tutup
            </Button>
            <Button
              type="button"
              isLoading={mutation.isPending}
              disabled={!selectedFile || warehouses.length === 0}
              onClick={() => mutation.mutate()}
            >
              Import Stok
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}