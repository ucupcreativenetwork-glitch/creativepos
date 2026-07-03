"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Printer, Receipt, Search, XCircle } from "lucide-react";
import { toast } from "sonner";
import { ConfirmDialog } from "@/components/ui/confirm-dialog";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { getErrorMessage } from "@/lib/api/client";
import { TransactionReceiptDialog } from "@/components/pos/transaction-receipt-dialog";
import { getTransactions, voidTransaction } from "@/lib/api/pos";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import type { PosTransaction } from "@/types/pos";

export default function PosHistoryPage() {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [voidTarget, setVoidTarget] = useState<PosTransaction | null>(null);
  const [voidReason] = useState("Kesalahan input");
  const [receiptTarget, setReceiptTarget] = useState<PosTransaction | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["pos", "transactions", search, page],
    queryFn: () => getTransactions({ search: search || undefined, page }),
    staleTime: 30 * 1000,
  });

  const voidMutation = useMutation({
    mutationFn: () => voidTransaction(voidTarget!.uuid, voidReason),
    onSuccess: () => {
      toast.success("Transaksi dibatalkan");
      setVoidTarget(null);
      queryClient.invalidateQueries({ queryKey: ["pos"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const transactions = data?.data ?? [];
  const meta = data?.meta;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="flex items-center gap-2 text-2xl font-bold tracking-tight">
          <Receipt className="h-7 w-7 text-primary" />
          Riwayat Transaksi POS
        </h1>
        <p className="mt-1 text-muted-foreground">
          Lihat dan batalkan transaksi yang sudah selesai
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Daftar Transaksi</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Cari nomor transaksi..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="pl-9"
            />
          </div>

          {isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-14 animate-pulse rounded-lg bg-slate-100" />
              ))}
            </div>
          ) : transactions.length === 0 ? (
            <p className="py-12 text-center text-muted-foreground">
              Belum ada transaksi
            </p>
          ) : (
            <div className="overflow-x-auto rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-medium">No. Transaksi</th>
                    <th className="px-4 py-3 font-medium">Outlet</th>
                    <th className="px-4 py-3 font-medium">Kasir</th>
                    <th className="px-4 py-3 font-medium text-right">Total</th>
                    <th className="px-4 py-3 font-medium">Status</th>
                    <th className="px-4 py-3 font-medium">Waktu</th>
                    <th className="px-4 py-3 font-medium text-right">Aksi</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {transactions.map((tx) => (
                    <tr key={tx.uuid}>
                      <td className="px-4 py-3 font-medium">
                        {tx.transaction_number}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {tx.outlet?.name ?? "—"}
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {tx.cashier?.name ?? "—"}
                      </td>
                      <td className="px-4 py-3 text-right font-medium">
                        {formatCurrency(tx.grand_total)}
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                            tx.status === "completed"
                              ? "bg-emerald-50 text-emerald-700"
                              : tx.status === "voided"
                                ? "bg-rose-50 text-rose-700"
                                : "bg-slate-100 text-slate-600"
                          }`}
                        >
                          {tx.status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {tx.completed_at
                          ? formatDate(tx.completed_at, {
                              day: "numeric",
                              month: "short",
                              hour: "2-digit",
                              minute: "2-digit",
                            })
                          : "—"}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <div className="flex items-center justify-end gap-1">
                          {tx.status === "completed" && (
                            <>
                              <Button
                                variant="ghost"
                                size="sm"
                                title="Cetak struk"
                                onClick={() => setReceiptTarget(tx)}
                              >
                                <Printer className="h-4 w-4 text-primary" />
                              </Button>
                              <Button
                                variant="ghost"
                                size="sm"
                                title="Void transaksi"
                                onClick={() => setVoidTarget(tx)}
                              >
                                <XCircle className="h-4 w-4 text-red-500" />
                              </Button>
                            </>
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

      <TransactionReceiptDialog
        open={receiptTarget !== null}
        transactionUuid={receiptTarget?.uuid ?? null}
        transactionNumber={receiptTarget?.transaction_number}
        onClose={() => setReceiptTarget(null)}
      />

      <ConfirmDialog
        open={voidTarget !== null}
        title="Batalkan Transaksi"
        description={`Yakin void transaksi ${voidTarget?.transaction_number}? Stok dan poin member (jika ada) akan dikembalikan.`}
        confirmLabel="Void"
        variant="destructive"
        isLoading={voidMutation.isPending}
        onClose={() => setVoidTarget(null)}
        onConfirm={() => voidMutation.mutate()}
      />
    </div>
  );
}