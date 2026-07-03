import { AlertCircle, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";

interface QueryErrorStateProps {
  message?: string;
  onRetry?: () => void;
  className?: string;
}

export function QueryErrorState({
  message = "Gagal memuat data. Periksa koneksi lalu coba lagi.",
  onRetry,
  className,
}: QueryErrorStateProps) {
  return (
    <div
      className={`flex flex-col items-center justify-center rounded-xl border border-red-200 bg-red-50 px-6 py-10 text-center ${className ?? ""}`}
    >
      <AlertCircle className="mb-3 h-10 w-10 text-red-500" />
      <p className="max-w-md text-sm text-red-800">{message}</p>
      {onRetry && (
        <Button variant="outline" size="sm" className="mt-4" onClick={onRetry}>
          <RefreshCw className="h-4 w-4" />
          Coba Lagi
        </Button>
      )}
    </div>
  );
}