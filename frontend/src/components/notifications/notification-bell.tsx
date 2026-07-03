"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Bell, CheckCheck } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  getNotifications,
  getUnreadNotificationCount,
  markAllNotificationsRead,
  markNotificationRead,
  type AppNotification,
} from "@/lib/api/notifications";
import { formatDate } from "@/lib/utils/format";
import { cn } from "@/lib/utils/cn";

const PANEL_WIDTH = 320;
const PANEL_GAP = 8;

interface PanelPosition {
  top: number;
  left: number;
  width: number;
  maxHeight: number;
}

function NotificationItem({
  notification,
  onRead,
}: {
  notification: AppNotification;
  onRead: (id: number) => void;
}) {
  const isUnread = !notification.read_at;

  return (
    <button
      type="button"
      onClick={() => isUnread && onRead(notification.id)}
      className={cn(
        "w-full px-4 py-3 text-left transition-colors hover:bg-slate-50",
        isUnread && "bg-primary/5"
      )}
    >
      <div className="flex items-start gap-2">
        {isUnread && (
          <span className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-primary" />
        )}
        <div className={cn("min-w-0 flex-1", !isUnread && "pl-4")}>
          <p className="break-words text-sm font-medium leading-snug">
            {notification.title}
          </p>
          <p className="mt-0.5 break-words text-xs leading-relaxed text-muted-foreground">
            {notification.body}
          </p>
          {notification.created_at && (
            <p className="mt-1 text-[10px] text-muted-foreground">
              {formatDate(notification.created_at, {
                day: "numeric",
                month: "short",
                hour: "2-digit",
                minute: "2-digit",
              })}
            </p>
          )}
        </div>
      </div>
    </button>
  );
}

function getPanelPosition(trigger: HTMLElement): PanelPosition {
  const rect = trigger.getBoundingClientRect();
  const viewportPadding = 12;
  const width = Math.min(PANEL_WIDTH, window.innerWidth - viewportPadding * 2);

  let left = rect.right - width;
  left = Math.max(
    viewportPadding,
    Math.min(left, window.innerWidth - width - viewportPadding)
  );

  const top = rect.bottom + PANEL_GAP;
  const maxHeight = Math.max(
    160,
    window.innerHeight - top - viewportPadding
  );

  return { top, left, width, maxHeight };
}

export function NotificationBell() {
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [panelPosition, setPanelPosition] = useState<PanelPosition | null>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);

  const { data: unreadCount = 0 } = useQuery({
    queryKey: ["notifications", "unread-count"],
    queryFn: getUnreadNotificationCount,
    refetchInterval: 60_000,
    staleTime: 30_000,
  });

  const { data: notificationsData, isLoading } = useQuery({
    queryKey: ["notifications", "list"],
    queryFn: () => getNotifications({ per_page: 15 }),
    enabled: open,
    staleTime: 15_000,
  });

  const markReadMutation = useMutation({
    mutationFn: markNotificationRead,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
    },
  });

  const markAllMutation = useMutation({
    mutationFn: markAllNotificationsRead,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
    },
  });

  const updatePanelPosition = useCallback(() => {
    if (!triggerRef.current) return;
    setPanelPosition(getPanelPosition(triggerRef.current));
  }, []);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!open) return;

    updatePanelPosition();

    function handleClickOutside(e: MouseEvent) {
      const target = e.target as Node;
      if (
        panelRef.current?.contains(target) ||
        triggerRef.current?.contains(target)
      ) {
        return;
      }
      setOpen(false);
    }

    function handleReposition() {
      updatePanelPosition();
    }

    document.addEventListener("mousedown", handleClickOutside);
    window.addEventListener("resize", handleReposition);
    window.addEventListener("scroll", handleReposition, true);

    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      window.removeEventListener("resize", handleReposition);
      window.removeEventListener("scroll", handleReposition, true);
    };
  }, [open, updatePanelPosition]);

  const notifications = notificationsData?.data ?? [];

  const panel =
    open && panelPosition && mounted ? (
      <div
        ref={panelRef}
        className="fixed z-[100] overflow-hidden rounded-xl border border-border bg-white shadow-xl"
        style={{
          top: panelPosition.top,
          left: panelPosition.left,
          width: panelPosition.width,
          maxHeight: panelPosition.maxHeight,
        }}
      >
        <div className="flex items-center justify-between gap-2 border-b border-border px-4 py-3">
          <p className="shrink-0 text-sm font-semibold">Notifikasi</p>
          {unreadCount > 0 && (
            <Button
              variant="ghost"
              size="sm"
              className="h-7 shrink-0 px-2 text-xs"
              onClick={() => markAllMutation.mutate()}
              isLoading={markAllMutation.isPending}
            >
              <CheckCheck className="h-3.5 w-3.5" />
              <span className="hidden sm:inline">Tandai semua</span>
              <span className="sm:hidden">Semua</span>
            </Button>
          )}
        </div>

        <div
          className="overflow-y-auto overscroll-contain"
          style={{ maxHeight: panelPosition.maxHeight - 52 }}
        >
          {isLoading ? (
            <div className="space-y-2 p-4">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="h-14 animate-pulse rounded-lg bg-slate-100" />
              ))}
            </div>
          ) : notifications.length === 0 ? (
            <p className="px-4 py-8 text-center text-sm text-muted-foreground">
              Tidak ada notifikasi
            </p>
          ) : (
            <div className="divide-y divide-border">
              {notifications.map((n) => (
                <NotificationItem
                  key={n.id}
                  notification={n}
                  onRead={(id) => markReadMutation.mutate(id)}
                />
              ))}
            </div>
          )}
        </div>
      </div>
    ) : null;

  return (
    <>
      <button
        ref={triggerRef}
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="relative rounded-lg p-2 text-muted-foreground transition-colors hover:bg-slate-100 hover:text-foreground"
        aria-label="Notifikasi"
        aria-expanded={open}
      >
        <Bell className="h-5 w-5" />
        {unreadCount > 0 && (
          <span className="absolute right-1 top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
            {unreadCount > 99 ? "99+" : unreadCount}
          </span>
        )}
      </button>

      {mounted && panel ? createPortal(panel, document.body) : null}
    </>
  );
}