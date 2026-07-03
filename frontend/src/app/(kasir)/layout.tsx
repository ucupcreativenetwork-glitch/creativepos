"use client";

import { useRouter } from "next/navigation";
import { useMutation } from "@tanstack/react-query";
import { LogOut } from "lucide-react";
import { useEffect } from "react";
import { toast } from "sonner";
import { logout } from "@/lib/api/auth";
import { useAuthStore } from "@/stores/auth-store";
import { Button } from "@/components/ui/button";

export default function KasirLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const { user, clearAuth, hasPermission } = useAuthStore();
  const mustChangePassword = !!user?.must_change_password;

  useEffect(() => {
    if (mustChangePassword) {
      router.replace("/change-password");
    }
  }, [mustChangePassword, router]);

  useEffect(() => {
    if (!user) return;
    if (!hasPermission("pos.create")) {
      toast.error("Anda tidak memiliki akses mesin kasir.");
      router.replace("/dashboard");
    }
  }, [user, hasPermission, router]);

  const logoutMutation = useMutation({
    mutationFn: logout,
    onSuccess: () => {
      clearAuth();
      toast.success("Berhasil keluar");
      router.push("/login");
    },
    onError: () => {
      clearAuth();
      router.push("/login");
    },
  });

  if (mustChangePassword || !user) {
    return null;
  }

  return (
    <div className="relative h-screen overflow-hidden bg-slate-950">
      <div className="absolute right-3 top-3 z-50">
        <Button
          variant="ghost"
          size="sm"
          className="h-9 gap-1.5 border border-slate-700/80 bg-slate-900/90 text-slate-300 backdrop-blur hover:bg-slate-800 hover:text-white"
          onClick={() => logoutMutation.mutate()}
          isLoading={logoutMutation.isPending}
        >
          <LogOut className="h-4 w-4" />
          <span className="hidden sm:inline">Keluar</span>
        </Button>
      </div>
      {children}
    </div>
  );
}