"use client";

import {
  CartesianGrid,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatCurrency } from "@/lib/utils/format";
import type { SalesChartPoint } from "@/types/dashboard";

interface SalesChartProps {
  data: SalesChartPoint[];
  isLoading?: boolean;
}

export function SalesChart({ data, isLoading }: SalesChartProps) {
  return (
    <Card className="col-span-full lg:col-span-2">
      <CardHeader>
        <CardTitle className="text-base">Grafik Penjualan</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          </div>
        ) : data.length === 0 ? (
          <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
            Belum ada data penjualan
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <LineChart data={data}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
              <XAxis
                dataKey="label"
                tick={{ fontSize: 12 }}
                tickFormatter={(v) => {
                  const parts = String(v).split("-");
                  return parts.length === 3
                    ? `${parts[2]}/${parts[1]}`
                    : String(v);
                }}
              />
              <YAxis
                tick={{ fontSize: 12 }}
                tickFormatter={(v) =>
                  new Intl.NumberFormat("id-ID", {
                    notation: "compact",
                    compactDisplay: "short",
                  }).format(v)
                }
              />
              <Tooltip
                formatter={(value) => [
                  formatCurrency(Number(value ?? 0)),
                  "Pendapatan",
                ]}
                labelFormatter={(label) => `Tanggal: ${label}`}
              />
              <Line
                type="monotone"
                dataKey="revenue"
                stroke="#2563EB"
                strokeWidth={2}
                dot={{ r: 3, fill: "#2563EB" }}
                activeDot={{ r: 5 }}
              />
            </LineChart>
          </ResponsiveContainer>
        )}
      </CardContent>
    </Card>
  );
}