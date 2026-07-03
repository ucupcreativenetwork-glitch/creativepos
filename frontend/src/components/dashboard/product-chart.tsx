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
import type { ProductPerformance } from "@/types/dashboard";

interface ProductChartProps {
  data: ProductPerformance[];
  isLoading?: boolean;
}

export function ProductChart({ data, isLoading }: ProductChartProps) {
  const chartData = data.map((p) => ({
    name: p.product_name.length > 18
      ? `${p.product_name.slice(0, 18)}…`
      : p.product_name,
    revenue: p.total_revenue,
    qty: p.total_qty,
  }));

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Produk Terlaris</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          </div>
        ) : chartData.length === 0 ? (
          <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
            Belum ada data produk
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <BarChart data={chartData} layout="vertical" margin={{ left: 8 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
              <XAxis
                type="number"
                tick={{ fontSize: 11 }}
                tickFormatter={(v) =>
                  new Intl.NumberFormat("id-ID", {
                    notation: "compact",
                  }).format(v)
                }
              />
              <YAxis
                type="category"
                dataKey="name"
                width={110}
                tick={{ fontSize: 11 }}
              />
              <Tooltip
                formatter={(value) => [
                  formatCurrency(Number(value ?? 0)),
                  "Pendapatan",
                ]}
              />
              <Bar dataKey="revenue" fill="#2563EB" radius={[0, 4, 4, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </CardContent>
    </Card>
  );
}