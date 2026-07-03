"use client";

import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import type { CustomerGrowthPoint } from "@/types/dashboard";

interface CustomerChartProps {
  data: CustomerGrowthPoint[];
  isLoading?: boolean;
}

export function CustomerChart({ data, isLoading }: CustomerChartProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Pertumbuhan Member</CardTitle>
      </CardHeader>
      <CardContent>
        {isLoading ? (
          <div className="flex h-64 items-center justify-center">
            <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
          </div>
        ) : data.length === 0 ? (
          <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
            Belum ada data member
          </div>
        ) : (
          <ResponsiveContainer width="100%" height={280}>
            <AreaChart data={data}>
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
              <YAxis tick={{ fontSize: 12 }} allowDecimals={false} />
              <Tooltip
                formatter={(value) => [Number(value ?? 0), "Member Baru"]}
                labelFormatter={(label) => `Tanggal: ${label}`}
              />
              <Area
                type="monotone"
                dataKey="count"
                stroke="#7C3AED"
                fill="#7C3AED"
                fillOpacity={0.15}
                strokeWidth={2}
              />
            </AreaChart>
          </ResponsiveContainer>
        )}
      </CardContent>
    </Card>
  );
}