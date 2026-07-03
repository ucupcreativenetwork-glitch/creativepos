"use client";

import { Printer } from "lucide-react";
import { Button } from "@/components/ui/button";
import { printElementById } from "@/lib/utils/print-receipt";
import { toast } from "sonner";

interface ReceiptDialogFooterProps {
  receiptElementId: string;
  onClose: () => void;
  closeLabel?: string;
}

export function ReceiptDialogFooter({
  receiptElementId,
  onClose,
  closeLabel = "Selesai",
}: ReceiptDialogFooterProps) {
  const handlePrint = () => {
    const printed = printElementById(receiptElementId);
    if (!printed) {
      toast.error("Gagal membuka dialog cetak.");
    }
  };

  return (
    <div className="flex gap-2 border-t border-border p-4">
      <Button variant="outline" className="flex-1" onClick={handlePrint}>
        <Printer className="h-4 w-4" />
        Cetak
      </Button>
      <Button className="flex-1" onClick={onClose}>
        {closeLabel}
      </Button>
    </div>
  );
}