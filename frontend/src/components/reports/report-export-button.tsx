"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { Download, FileSpreadsheet, FileText } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { getErrorMessage } from "@/lib/api/client";
import {
  downloadReportExport,
  getExportStatus,
  requestReportExport,
} from "@/lib/api/reports";
import type { ExportReportPayload } from "@/types/report";

interface ReportExportButtonProps {
  reportType: ExportReportPayload["report_type"];
  dateFrom: string;
  dateTo: string;
  outletId?: number;
  disabled?: boolean;
}

const POLL_INTERVAL_MS = 3000;

export function ReportExportButton({
  reportType,
  dateFrom,
  dateTo,
  outletId,
  disabled = false,
}: ReportExportButtonProps) {
  const [format, setFormat] = useState<"xlsx" | "pdf">("xlsx");
  const [exporting, setExporting] = useState(false);
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const stopPolling = useCallback(() => {
    if (pollRef.current) {
      clearInterval(pollRef.current);
      pollRef.current = null;
    }
  }, []);

  useEffect(() => () => stopPolling(), [stopPolling]);

  const pollUntilReady = useCallback(
    (uuid: string) => {
      stopPolling();

      pollRef.current = setInterval(async () => {
        try {
          const status = await getExportStatus(uuid);

          if (status.status === "completed") {
            stopPolling();
            setExporting(false);
            await downloadReportExport(uuid, status);
            toast.success("Laporan berhasil diunduh");
          } else if (status.status === "failed") {
            stopPolling();
            setExporting(false);
            toast.error(status.error_message ?? "Export gagal");
          }
        } catch (error) {
          stopPolling();
          setExporting(false);
          toast.error(getErrorMessage(error));
        }
      }, POLL_INTERVAL_MS);
    },
    [stopPolling]
  );

  const handleExport = async () => {
    setExporting(true);

    try {
      const result = await requestReportExport({
        report_type: reportType,
        format,
        date_from: dateFrom,
        date_to: dateTo,
        outlet_id: outletId,
        type: "daily",
      });

      if (result.status === "completed") {
        await downloadReportExport(result.uuid, result);
        toast.success("Laporan berhasil diunduh");
        setExporting(false);
        return;
      }

      if (result.status === "failed") {
        toast.error(result.error_message ?? "Export gagal");
        setExporting(false);
        return;
      }

      toast.info("Export sedang diproses...");
      pollUntilReady(result.uuid);
    } catch (error) {
      setExporting(false);
      toast.error(getErrorMessage(error));
    }
  };

  return (
    <div className="flex items-center gap-2">
      <select
        value={format}
        onChange={(e) => setFormat(e.target.value as "xlsx" | "pdf")}
        disabled={exporting || disabled}
        className="h-10 rounded-lg border border-border bg-white px-3 text-sm"
      >
        <option value="xlsx">Excel (.xlsx)</option>
        <option value="pdf">PDF (.pdf)</option>
      </select>
      <Button
        variant="outline"
        onClick={handleExport}
        isLoading={exporting}
        disabled={disabled}
      >
        {format === "xlsx" ? (
          <FileSpreadsheet className="h-4 w-4" />
        ) : (
          <FileText className="h-4 w-4" />
        )}
        <Download className="h-4 w-4" />
        Ekspor
      </Button>
    </div>
  );
}