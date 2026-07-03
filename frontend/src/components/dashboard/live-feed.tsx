"use client";

import { ShoppingCart } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import type { LiveTransaction } from "@/types/dashboard";

interface LiveFeedProps {
  data: LiveTransaction[];
  isLoading?: boolean;
}

export function LiveFeed({ data, isLoading }: LiveFeedProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Transaksi Terbaru</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className="h-12 animate-pulse rounded-lg bg-slate-100" />
            ))}
          </div>
        ) : data.length === 0 ? (
          <p className="py-8 text-center text-sm text-muted-foreground">
            Belum ada transaksi
          </p>
        ) : (
          <div className="space-y-3">
            {data.map((tx) => (
              <div
                key={tx.id}
                className="flex items-center justify-between rounded-lg border border-border p-3"
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary/10 text-primary">
                    <ShoppingCart className="h-4 w-4" />
                  </div>
                  <div>
                    <p className="text-sm font-medium">{tx.transaction_number}</p>
                    <p className="text-xs text-muted-foreground">
                      {tx.outlet ?? "—"} · {tx.cashier ?? "—"}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm font-semibold text-emerald-600">
                    {formatCurrency(tx.grand_total)}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {tx.created_at
                      ? formatDate(tx.created_at, {
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
    </Card>
  );
}