"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  AlertTriangle,
  ArrowDownToLine,
  ArrowUpFromLine,
  Package,
  Pencil,
  Plus,
  Search,
  SlidersHorizontal,
  Trash2,
} from "lucide-react";
import { toast } from "sonner";
import { ProductFormDialog } from "@/components/inventory/product-form-dialog";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { RawMaterialsTab } from "@/components/inventory/raw-materials-tab";
import { RecipeTab } from "@/components/inventory/recipe-tab";
import {
  StockDialog,
  type StockAction,
} from "@/components/inventory/stock-dialog";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { getErrorMessage } from "@/lib/api/client";
import {
  deleteProduct,
  getCategories,
  getProducts,
  getStockAlerts,
  getStockMovements,
  getWarehouses,
} from "@/lib/api/inventory";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import type { Product } from "@/types/inventory";

type InventoryTab = "products" | "raw-materials" | "recipes";

export default function InventoryPage() {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState<InventoryTab>("products");
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<number | undefined>();
  const [page, setPage] = useState(1);
  const [formOpen, setFormOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [stockOpen, setStockOpen] = useState(false);
  const [stockAction, setStockAction] = useState<StockAction>("in");
  const [stockProduct, setStockProduct] = useState<Product | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Product | null>(null);

  const { data: categoriesData } = useQuery({
    queryKey: ["inventory", "categories"],
    queryFn: () => getCategories({ per_page: 100 }),
    staleTime: 5 * 60 * 1000,
  });

  const { data: warehouses = [] } = useQuery({
    queryKey: ["inventory", "warehouses"],
    queryFn: getWarehouses,
    staleTime: 5 * 60 * 1000,
  });

  const { data: productsData, isLoading, isError, error } = useQuery({
    queryKey: ["inventory", "products", search, categoryFilter, page],
    queryFn: () =>
      getProducts({
        search: search || undefined,
        category_id: categoryFilter,
        page,
        per_page: 10,
      }),
    staleTime: 30 * 1000,
  });

  const { data: alerts = [] } = useQuery({
    queryKey: ["inventory", "alerts"],
    queryFn: getStockAlerts,
    staleTime: 60 * 1000,
  });

  const { data: movementsData } = useQuery({
    queryKey: ["inventory", "movements"],
    queryFn: () => getStockMovements({ per_page: 8 }),
    staleTime: 30 * 1000,
  });

  const deleteMutation = useMutation({
    mutationFn: deleteProduct,
    onSuccess: () => {
      toast.success("Produk berhasil dihapus");
      queryClient.invalidateQueries({ queryKey: ["inventory"] });
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const categories = categoriesData?.data ?? [];
  const products = productsData?.data ?? [];
  const meta = productsData?.meta;
  const movements = movementsData?.data ?? [];

  const refresh = () => {
    queryClient.invalidateQueries({ queryKey: ["inventory"] });
  };

  const openStock = (product: Product, action: StockAction) => {
    setStockProduct(product);
    setStockAction(action);
    setStockOpen(true);
  };

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Inventori</h1>
          <p className="mt-1 text-muted-foreground">
            Kelola produk, stok, dan pergerakan barang
          </p>
        </div>
        {activeTab === "products" && (
          <Button
            onClick={() => {
              setEditingProduct(null);
              setFormOpen(true);
            }}
          >
            <Plus className="h-4 w-4" />
            Tambah Produk
          </Button>
        )}
      </div>

      <div className="flex gap-2 border-b border-border">
        {(
          [
            { id: "products" as const, label: "Produk" },
            { id: "raw-materials" as const, label: "Bahan Baku" },
            { id: "recipes" as const, label: "Resep" },
          ] as const
        ).map((tab) => (
          <button
            key={tab.id}
            type="button"
            onClick={() => setActiveTab(tab.id)}
            className={`border-b-2 px-4 py-2 text-sm font-medium transition-colors ${
              activeTab === tab.id
                ? "border-primary text-primary"
                : "border-transparent text-muted-foreground hover:text-foreground"
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {activeTab === "raw-materials" && <RawMaterialsTab />}
      {activeTab === "recipes" && <RecipeTab />}

      {activeTab === "products" && alerts.length > 0 && (
        <Card className="border-amber-200 bg-amber-50/50">
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-base text-amber-800">
              <AlertTriangle className="h-4 w-4" />
              Peringatan Stok Menipis ({alerts.length})
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap gap-2">
              {alerts.slice(0, 5).map((alert) => (
                <span
                  key={`${alert.product.id}-${alert.warehouse.id}`}
                  className="rounded-full bg-white px-3 py-1 text-xs text-amber-900 ring-1 ring-amber-200"
                >
                  {alert.product.name}: {alert.quantity} / min {alert.product.min_stock}
                </span>
              ))}
            </div>
          </CardContent>
        </Card>
      )}

      {activeTab === "products" && <Card>
        <CardHeader>
          <CardTitle className="text-base">Daftar Produk</CardTitle>
          <CardDescription>
            {meta ? `${meta.total} produk terdaftar` : "Memuat produk..."}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-3 sm:flex-row">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Cari nama, SKU, atau barcode..."
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setPage(1);
                }}
                className="pl-9"
              />
            </div>
            <select
              value={categoryFilter ?? ""}
              onChange={(e) => {
                setCategoryFilter(
                  e.target.value ? Number(e.target.value) : undefined
                );
                setPage(1);
              }}
              className="h-10 rounded-lg border border-border bg-white px-3 text-sm"
            >
              <option value="">Semua Kategori</option>
              {categories.map((cat) => (
                <option key={cat.id} value={cat.id}>
                  {cat.name}
                </option>
              ))}
            </select>
          </div>

          {isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-14 animate-pulse rounded-lg bg-slate-100" />
              ))}
            </div>
          ) : isError ? (
            <div className="flex flex-col items-center py-12 text-center">
              <AlertTriangle className="mb-3 h-10 w-10 text-destructive" />
              <p className="font-medium">Gagal memuat produk</p>
              <p className="mt-1 text-sm text-muted-foreground">
                {getErrorMessage(error)}
              </p>
            </div>
          ) : products.length === 0 ? (
            <div className="flex flex-col items-center py-12 text-center">
              <Package className="mb-3 h-10 w-10 text-muted-foreground" />
              <p className="font-medium">
                {search || categoryFilter
                  ? "Produk tidak ditemukan"
                  : "Belum ada produk"}
              </p>
              <p className="mt-1 text-sm text-muted-foreground">
                {search || categoryFilter
                  ? "Coba kata kunci atau filter kategori lain"
                  : "Tambahkan produk pertama Anda untuk mulai mengelola inventori"}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-medium">Produk</th>
                    <th className="px-4 py-3 font-medium">SKU</th>
                    <th className="px-4 py-3 font-medium">Kategori</th>
                    <th className="px-4 py-3 font-medium text-right">Harga</th>
                    <th className="px-4 py-3 font-medium text-right">Stok</th>
                    <th className="px-4 py-3 font-medium text-center">Status</th>
                    <th className="px-4 py-3 font-medium text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {products.map((product) => {
                    const isLow =
                      product.track_stock &&
                      product.total_stock <= product.min_stock;

                    return (
                      <tr key={product.uuid} className="hover:bg-slate-50/50">
                        <td className="px-4 py-3 font-medium">{product.name}</td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {product.sku}
                        </td>
                        <td className="px-4 py-3 text-muted-foreground">
                          {product.category?.name ?? "—"}
                        </td>
                        <td className="px-4 py-3 text-right">
                          {formatCurrency(product.base_price)}
                        </td>
                        <td className="px-4 py-3 text-right">
                          <span className={isLow ? "font-semibold text-amber-600" : ""}>
                            {product.track_stock ? product.total_stock : "—"}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-center">
                          <span
                            className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                              product.is_active
                                ? "bg-emerald-50 text-emerald-700"
                                : "bg-slate-100 text-slate-600"
                            }`}
                          >
                            {product.is_active ? "Aktif" : "Nonaktif"}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center justify-end gap-1">
                            {product.track_stock && (
                              <>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  title="Tambah stok"
                                  onClick={() => openStock(product, "in")}
                                >
                                  <ArrowDownToLine className="h-4 w-4" />
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  title="Kurang stok"
                                  onClick={() => openStock(product, "out")}
                                >
                                  <ArrowUpFromLine className="h-4 w-4" />
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  title="Sesuaikan stok"
                                  onClick={() => openStock(product, "adjustment")}
                                >
                                  <SlidersHorizontal className="h-4 w-4" />
                                </Button>
                              </>
                            )}
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => {
                                setEditingProduct(product);
                                setFormOpen(true);
                              }}
                            >
                              <Pencil className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setDeleteTarget(product)}
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
            <div className="flex items-center justify-between pt-2">
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
      </Card>}

      {activeTab === "products" && <Card>
        <CardHeader>
          <CardTitle className="text-base">Riwayat Pergerakan Stok</CardTitle>
        </CardHeader>
        <CardContent>
          {movements.length === 0 ? (
            <p className="py-6 text-center text-sm text-muted-foreground">
              Belum ada pergerakan stok
            </p>
          ) : (
            <div className="space-y-2">
              {movements.map((movement) => (
                <div
                  key={movement.id}
                  className="flex items-center justify-between rounded-lg border border-border px-4 py-3 text-sm"
                >
                  <div>
                    <p className="font-medium">
                      {movement.product?.name ?? "—"}{" "}
                      <span className="text-muted-foreground">
                        ({movement.type})
                      </span>
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {movement.warehouse?.name ?? "—"}
                      {movement.notes ? ` · ${movement.notes}` : ""}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="font-medium">
                      {movement.before_quantity} → {movement.after_quantity}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {movement.created_at
                        ? formatDate(movement.created_at, {
                            day: "numeric",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })
                        : "—"}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>}

      <ProductFormDialog
        open={formOpen}
        onClose={() => {
          setFormOpen(false);
          setEditingProduct(null);
        }}
        onSuccess={refresh}
        categories={categories}
        product={editingProduct}
      />

      <StockDialog
        open={stockOpen}
        action={stockAction}
        product={stockProduct}
        warehouses={warehouses}
        onClose={() => {
          setStockOpen(false);
          setStockProduct(null);
        }}
        onSuccess={refresh}
      />

      <ConfirmDialog
        open={deleteTarget !== null}
        title="Hapus Produk"
        description={`Yakin ingin menghapus produk "${deleteTarget?.name}"? Tindakan ini tidak dapat dibatalkan.`}
        confirmLabel="Hapus"
        variant="destructive"
        isLoading={deleteMutation.isPending}
        onClose={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) {
            deleteMutation.mutate(deleteTarget.uuid, {
              onSuccess: () => setDeleteTarget(null),
            });
          }
        }}
      />
    </div>
  );
}