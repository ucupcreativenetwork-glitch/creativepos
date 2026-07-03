"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, Circle, Sparkles } from "lucide-react";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { QueryErrorState } from "@/components/ui/query-error-state";
import { getErrorMessage } from "@/lib/api/client";
import { getOnboardingChecklist } from "@/lib/api/settings";
import { cn } from "@/lib/utils/cn";

export function SetupChecklistCard() {
  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["settings", "onboarding-checklist"],
    queryFn: getOnboardingChecklist,
    staleTime: 60 * 1000,
  });

  if (isLoading) {
    return (
      <Card>
        <CardHeader>
          <div className="h-5 w-40 animate-pulse rounded bg-slate-100" />
          <div className="mt-2 h-4 w-64 animate-pulse rounded bg-slate-100" />
        </CardHeader>
        <CardContent className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="h-12 animate-pulse rounded-lg bg-slate-100" />
          ))}
        </CardContent>
      </Card>
    );
  }

  if (isError) {
    return (
      <QueryErrorState
        message={getErrorMessage(error)}
        onRetry={() => void refetch()}
      />
    );
  }

  if (!data || data.progress_percent >= 100) {
    return null;
  }

  return (
    <Card className="overflow-hidden border-primary/20 bg-gradient-to-br from-primary/5 to-white">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between gap-4">
          <div>
            <CardTitle className="flex items-center gap-2 text-base">
              <Sparkles className="h-4 w-4 text-primary" />
              Lanjutkan setup bisnis
            </CardTitle>
            <CardDescription className="mt-1">
              {data.completed_count} dari {data.total_count} langkah selesai
            </CardDescription>
          </div>
          <span className="rounded-full bg-primary/10 px-3 py-1 text-sm font-semibold text-primary">
            {data.progress_percent}%
          </span>
        </div>
        <div className="mt-3 h-2 overflow-hidden rounded-full bg-slate-100">
          <div
            className="h-full rounded-full bg-primary transition-all duration-500"
            style={{ width: `${data.progress_percent}%` }}
          />
        </div>
      </CardHeader>
      <CardContent className="space-y-2">
        {data.items.map((item) => (
          <Link
            key={item.id}
            href={item.href}
            className={cn(
              "flex items-center gap-3 rounded-lg border px-3 py-2.5 transition-colors",
              item.done
                ? "border-emerald-100 bg-emerald-50/50"
                : "border-border bg-white hover:border-primary/30 hover:bg-primary/5"
            )}
          >
            {item.done ? (
              <CheckCircle2 className="h-5 w-5 shrink-0 text-emerald-600" />
            ) : (
              <Circle className="h-5 w-5 shrink-0 text-muted-foreground" />
            )}
            <div className="min-w-0 flex-1">
              <p
                className={cn(
                  "text-sm font-medium",
                  item.done && "text-emerald-800"
                )}
              >
                {item.label}
              </p>
              <p className="truncate text-xs text-muted-foreground">
                {item.description}
              </p>
            </div>
          </Link>
        ))}
      </CardContent>
    </Card>
  );
}