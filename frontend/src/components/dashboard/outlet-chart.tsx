"use client";

import {
  Bar,
  BarChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatCurrency } from "@/lib/utils/format";
import type { OutletPerformance } from "@/types/dashboard";

interface OutletChartProps {
  data: OutletPerformance[];
  isLoading?: boolean;
}

export function OutletChart({ data, isLoading }: OutletChartProps) {
  const chartData = data.map((o) => ({
    name: o.name.length > 14 ? `${o.name.slice(0, 14)}…` : o.name,
    revenue: o.revenue,
    transactions: o.transactions,
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Performa Outlet</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          </div>
        ) : chartData.length === 0 ? (
          <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
            Belum ada data outlet
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
              <XAxis dataKey="name" tick={{ fontSize: 11 }} />
              <YAxis
                tick={{ fontSize: 11 }}
                tickFormatter={(v) =>
                  new Intl.NumberFormat("id-ID", {
                    notation: "compact",
                  }).format(v)
                }
              />
              <Tooltip
                formatter={(value, name) => [
                  name === "revenue"
                    ? formatCurrency(Number(value ?? 0))
                    : Number(value ?? 0),
                  name === "revenue" ? "Pendapatan" : "Transaksi",
                ]}
              />
              <Bar dataKey="revenue" fill="#059669" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </CardContent>
    </Card>
  );
}