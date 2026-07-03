"use client";

import { useQuery } from "@tanstack/react-query";
import { Download, FileSpreadsheet } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  downloadReportExport,
  getReportExports,
} from "@/lib/api/reports";
import { formatDate } from "@/lib/utils/format";
import type { ReportExportStatus } from "@/types/report";

const statusLabels: Record<ReportExportStatus["status"], string> = {
  pending: "Menunggu",
  processing: "Memproses",
  completed: "Selesai",
  failed: "Gagal",
};

const statusColors: Record<ReportExportStatus["status"], string> = {
  pending: "bg-amber-50 text-amber-700",
  processing: "bg-blue-50 text-blue-700",
  completed: "bg-emerald-50 text-emerald-700",
  failed: "bg-red-50 text-red-700",
};

const reportTypeLabels: Record<string, string> = {
  sales: "Penjualan",
  products: "Produk",
  inventory: "Inventori",
  members: "Member",
};

export function ReportExportHistory() {
  const { data, isLoading, refetch } = useQuery({
    queryKey: ["reports", "exports"],
    queryFn: () => getReportExports({ per_page: 15 }),
    staleTime: 30_000,
    refetchInterval: (query) => {
      const exports = query.state.data?.data ?? [];
      const hasPending = exports.some(
        (e) => e.status === "pending" || e.status === "processing"
      );
      return hasPending ? 5000 : false;
    },
  });

  const exports = data?.data ?? [];

  async function handleDownload(item: ReportExportStatus) {
    if (item.status !== "completed") return;
    await downloadReportExport(item.uuid, item);
  }

  return (
    <Card>
      <CardHeader className="flex flex-row items-start justify-between gap-4">
        <div>
          <CardTitle className="flex items-center gap-2 text-base">
            <FileSpreadsheet className="h-4 w-4" />
            Riwayat Export
          </CardTitle>
          <CardDescription>
            File laporan yang pernah diekspor
          </CardDescription>
        </div>
        <Button variant="outline" size="sm" onClick={() => refetch()}>
          Refresh
        </Button>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="h-12 animate-pulse rounded-lg bg-slate-100" />
            ))}
          </div>
        ) : exports.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            Belum ada riwayat export
          </p>
        ) : (
          <div className="overflow-x-auto rounded-lg border border-border">
            <table className="w-full text-sm">
              <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                <tr>
                  <th className="px-4 py-3 font-medium">Laporan</th>
                  <th className="px-4 py-3 font-medium">Format</th>
                  <th className="px-4 py-3 font-medium">Status</th>
                  <th className="px-4 py-3 font-medium">Dibuat</th>
                  <th className="px-4 py-3 font-medium text-right">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {exports.map((item) => (
                  <tr key={item.uuid} className="hover:bg-slate-50/50">
                    <td className="px-4 py-3 font-medium">
                      {reportTypeLabels[item.report_type] ?? item.report_type}
                    </td>
                    <td className="px-4 py-3 uppercase text-muted-foreground">
                      {item.format}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                          statusColors[item.status]
                        }`}
                      >
                        {statusLabels[item.status]}
                      </span>
                      {item.error_message && (
                        <p className="mt-1 text-[10px] text-red-600">
                          {item.error_message}
                        </p>
                      )}
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">
                      {item.created_at
                        ? formatDate(item.created_at, {
                            day: "numeric",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })
                        : "—"}
                    </td>
                    <td className="px-4 py-3 text-right">
                      {item.status === "completed" && (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => handleDownload(item)}
                        >
                          <Download className="h-3.5 w-3.5" />
                          Unduh
                        </Button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </CardContent>
    </Card>
  );
}