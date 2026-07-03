"use client";

import { useRef, useState } from "react";
import { useMutation } from "@tanstack/react-query";
import { Download, FileSpreadsheet, Upload, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { getErrorMessage } from "@/lib/api/client";
import { importProducts } from "@/lib/api/inventory";
import type { ProductImportResult } from "@/types/inventory";

interface ProductImportDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

const TEMPLATE_URL = "/templates/products-import.csv";

export function ProductImportDialog({
  open,
  onClose,
  onSuccess,
}: ProductImportDialogProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [result, setResult] = useState<ProductImportResult | null>(null);

  const mutation = useMutation({
    mutationFn: () => {
      if (!selectedFile) {
        throw new Error("Pilih file CSV atau Excel terlebih dahulu.");
      }

      return importProducts(selectedFile);
    },
    onSuccess: (data) => {
      setResult(data);
      toast.success(
        `Import selesai: ${data.created} berhasil, ${data.skipped} dilewati.`,
      );
      if (data.created > 0) {
        onSuccess();
      }
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const handleClose = () => {
    setSelectedFile(null);
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
            <h2 className="text-lg font-semibold">Import Produk Massal</h2>
            <p className="text-sm text-muted-foreground">
              Upload CSV atau Excel untuk menambah banyak produk sekaligus
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
              <code>name</code>, <code>sku</code>, <code>base_price</code>
            </p>
            <p className="mt-2 text-muted-foreground">
              Opsional: <code>cost_price</code>, <code>barcode</code>,{" "}
              <code>category_name</code>, <code>initial_stock</code>,{" "}
              <code>min_stock</code>, <code>track_stock</code>
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

          <div className="flex items-center gap-3">
            <input
              ref={fileInputRef}
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

          {result && (
            <div className="rounded-lg border border-border bg-slate-50 p-4 text-sm">
              <div className="flex items-center gap-2 font-medium">
                <FileSpreadsheet className="h-4 w-4" />
                Hasil import
              </div>
              <p className="mt-2">
                Berhasil: <strong>{result.created}</strong> · Dilewati:{" "}
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
              disabled={!selectedFile}
              onClick={() => mutation.mutate()}
            >
              Import Produk
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}