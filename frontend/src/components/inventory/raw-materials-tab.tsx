"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertTriangle,
  ArrowDownToLine,
  ArrowUpFromLine,
  Pencil,
  Plus,
  Search,
  Trash2,
} from "lucide-react";
import { toast } from "sonner";
import { RawMaterialFormDialog } from "@/components/inventory/raw-material-form-dialog";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { getErrorMessage } from "@/lib/api/client";
import {
  deleteRawMaterial,
  getRawMaterialAlerts,
  getRawMaterials,
  rawMaterialStockIn,
  rawMaterialStockOut,
} from "@/lib/api/inventory";
import { formatCurrency } from "@/lib/utils/format";
import type { RawMaterial } from "@/types/inventory";

const UNIT_LABELS: Record<string, string> = {
  gram: "g",
  ml: "ml",
  pcs: "pcs",
  liter: "L",
};

export function RawMaterialsTab() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<RawMaterial | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<RawMaterial | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["inventory", "raw-materials", search, page],
    queryFn: () =>
      getRawMaterials({ search: search || undefined, page, per_page: 10 }),
    staleTime: 30 * 1000,
  });

  const { data: alerts = [] } = useQuery({
    queryKey: ["inventory", "raw-material-alerts"],
    queryFn: getRawMaterialAlerts,
    staleTime: 60 * 1000,
  });

  const deleteMutation = useMutation({
    mutationFn: deleteRawMaterial,
    onSuccess: () => {
      toast.success("Bahan baku dihapus");
      queryClient.invalidateQueries({ queryKey: ["inventory"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const stockMutation = useMutation({
    mutationFn: async ({
      material,
      type,
    }: {
      material: RawMaterial;
      type: "in" | "out";
    }) => {
      const qty = prompt(
        `Jumlah stok ${type === "in" ? "masuk" : "keluar"} (${material.unit}):`,
        "1"
      );
      if (!qty) return;
      const quantity = Number(qty);
      if (quantity <= 0) throw new Error("Jumlah harus lebih dari 0");

      if (type === "in") {
        await rawMaterialStockIn(material.id, { quantity });
      } else {
        await rawMaterialStockOut(material.id, { quantity });
      }
    },
    onSuccess: () => {
      toast.success("Stok bahan baku diperbarui");
      queryClient.invalidateQueries({ queryKey: ["inventory"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const materials = data?.data ?? [];
  const meta = data?.meta;

  const refresh = () => {
    queryClient.invalidateQueries({ queryKey: ["inventory"] });
  };

  return (
    <div className="space-y-6">
      {alerts.length > 0 && (
        <Card className="border-red-200 bg-red-50/50">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-base text-red-800">
              <AlertTriangle className="h-4 w-4" />
              Bahan Baku Menipis ({alerts.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {alerts.slice(0, 6).map((item) => (
                <span
                  key={item.id}
                  className="rounded-full bg-white px-3 py-1 text-xs text-red-900 ring-1 ring-red-200"
                >
                  {item.name}: {item.current_stock}
                  {UNIT_LABELS[item.unit]} / min {item.min_stock}
                  {UNIT_LABELS[item.unit]}
                </span>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader className="flex flex-row items-center justify-between gap-4">
          <div>
            <CardTitle className="text-base">Bahan Baku</CardTitle>
            <CardDescription>
              {meta ? `${meta.total} bahan baku terdaftar` : "Memuat..."}
            </CardDescription>
          </div>
          <Button
            size="sm"
            onClick={() => {
              setEditing(null);
              setFormOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            Tambah
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Cari bahan baku..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="pl-9"
            />
          </div>

          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-12 animate-pulse rounded-lg bg-slate-100" />
              ))}
            </div>
          ) : materials.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">
              Belum ada bahan baku
            </p>
          ) : (
            <div className="overflow-x-auto rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-medium">Nama</th>
                    <th className="px-4 py-3 font-medium">Satuan</th>
                    <th className="px-4 py-3 font-medium text-right">Stok</th>
                    <th className="px-4 py-3 font-medium text-right">Min</th>
                    <th className="px-4 py-3 font-medium text-right">Biaya/Satuan</th>
                    <th className="px-4 py-3 font-medium text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {materials.map((material) => {
                    const isLow = material.is_low_stock;

                    return (
                      <tr key={material.id} className="hover:bg-slate-50/50">
                        <td className="px-4 py-3 font-medium">{material.name}</td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {UNIT_LABELS[material.unit] ?? material.unit}
                        </td>
                        <td className={`px-4 py-3 text-right ${isLow ? "font-semibold text-red-600" : ""}`}>
                          {material.current_stock}
                          {isLow && (
                            <AlertTriangle className="ml-1 inline h-3.5 w-3.5 text-red-500" />
                          )}
                        </td>
                        <td className="px-4 py-3 text-right text-muted-foreground">
                          {material.min_stock}
                        </td>
                        <td className="px-4 py-3 text-right">
                          {formatCurrency(material.cost_per_unit)}
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center justify-end gap-1">
                            <Button
                              variant="ghost"
                              size="sm"
                              title="Stok masuk"
                              onClick={() =>
                                stockMutation.mutate({ material, type: "in" })
                              }
                            >
                              <ArrowDownToLine className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              title="Stok keluar"
                              onClick={() =>
                                stockMutation.mutate({ material, type: "out" })
                              }
                            >
                              <ArrowUpFromLine className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => {
                                setEditing(material);
                                setFormOpen(true);
                              }}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setDeleteTarget(material)}
                            >
                              <Trash2 className="h-4 w-4 text-red-500" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
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

      <RawMaterialFormDialog
        open={formOpen}
        material={editing}
        onClose={() => {
          setFormOpen(false);
          setEditing(null);
        }}
        onSuccess={refresh}
      />

      <ConfirmDialog
        open={deleteTarget !== null}
        title="Hapus Bahan Baku"
        description={`Yakin ingin menghapus "${deleteTarget?.name}"?`}
        confirmLabel="Hapus"
        variant="destructive"
        isLoading={deleteMutation.isPending}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) {
            deleteMutation.mutate(deleteTarget.id, {
              onSuccess: () => setDeleteTarget(null),
            });
          }
        }}
      />
    </div>
  );
}