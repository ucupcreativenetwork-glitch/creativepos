"use client";

import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Coins, Pencil, Wallet, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import {
  adjustMemberPoints,
  getMemberPoints,
  redeemPoints,
} from "@/lib/api/members";
import { getMembers } from "@/lib/api/members";
import {
  getWalletTransactions,
  topupWallet,
  transferWallet,
  withdrawWallet,
} from "@/lib/api/wallet";
import { usePackageFeatures } from "@/hooks/usePackageFeatures";
import { formatCurrency, formatDate } from "@/lib/utils/format";
import type { Member } from "@/types/loyalty";

interface MemberDetailPanelProps {
  member: Member | null;
  onClose: () => void;
  onRefresh: () => void;
  onEdit?: (member: Member) => void;
}

export function MemberDetailPanel({
  member,
  onClose,
  onRefresh,
  onEdit,
}: MemberDetailPanelProps) {
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<"points" | "wallet">("points");
  const [redeemPoints_, setRedeemPoints] = useState("");
  const [adjustPoints_, setAdjustPoints] = useState("100");
  const [adjustNote, setAdjustNote] = useState("Bonus / penyesuaian manual");
  const [walletAmount, setWalletAmount] = useState("50000");
  const [transferToId, setTransferToId] = useState<number | "">("");
  const { hasWallet } = usePackageFeatures();

  const { data: pointsData } = useQuery({
    queryKey: ["members", member?.uuid, "points"],
    queryFn: () => getMemberPoints(member!.uuid),
    enabled: !!member && tab === "points",
  });

  const { data: walletTx } = useQuery({
    queryKey: ["wallet", member?.id, "transactions"],
    queryFn: () => getWalletTransactions(member!.uuid),
    enabled: !!member && tab === "wallet",
  });

  const { data: allMembers } = useQuery({
    queryKey: ["members", "transfer-list"],
    queryFn: () => getMembers({ per_page: 100 }),
    enabled: !!member && tab === "wallet" && hasWallet,
  });

  const pointBalance = pointsData?.balance ?? member?.points?.balance ?? 0;
  const minRedeem = pointsData?.config?.min_redeem_points ?? 100;
  const redeemAmount = Number(redeemPoints_) || 0;

  const canRedeem =
    redeemAmount >= minRedeem &&
    redeemAmount <= pointBalance &&
    redeemAmount > 0;

  useEffect(() => {
    if (!member) return;

    const balance = pointsData?.balance ?? member.points?.balance ?? 0;
    const min = pointsData?.config?.min_redeem_points ?? 100;

    if (balance >= min) {
      setRedeemPoints(String(Math.min(min, balance)));
    } else {
      setRedeemPoints("");
    }
  }, [member?.uuid, pointsData?.balance, pointsData?.config?.min_redeem_points, member?.points?.balance]);

  const redeemHint = useMemo(() => {
    if (pointBalance <= 0) {
      return "Member belum punya poin. Lakukan transaksi POS dengan member ini, atau tambah poin manual di bawah.";
    }
    if (pointBalance < minRedeem) {
      return `Saldo ${pointBalance} poin — minimal redeem ${minRedeem} poin.`;
    }
    if (redeemAmount > pointBalance) {
      return `Maksimal bisa redeem ${pointBalance} poin.`;
    }
    if (redeemAmount > 0 && redeemAmount < minRedeem) {
      return `Minimal redeem ${minRedeem} poin.`;
    }
    return null;
  }, [pointBalance, minRedeem, redeemAmount]);

  const redeemMutation = useMutation({
    mutationFn: () => {
      if (!canRedeem) {
        throw new Error(redeemHint ?? "Jumlah redeem tidak valid.");
      }
      return redeemPoints(member!.uuid, redeemAmount);
    },
    onSuccess: (result) => {
      toast.success(
        `Redeem berhasil — diskon ${formatCurrency(result.discount_value)}`
      );
      queryClient.invalidateQueries({ queryKey: ["members"] });
      queryClient.invalidateQueries({ queryKey: ["members", member!.uuid, "points"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const adjustMutation = useMutation({
    mutationFn: () =>
      adjustMemberPoints(
        member!.uuid,
        Number(adjustPoints_),
        adjustNote.trim()
      ),
    onSuccess: () => {
      toast.success("Poin berhasil ditambahkan");
      queryClient.invalidateQueries({ queryKey: ["members"] });
      queryClient.invalidateQueries({ queryKey: ["members", member!.uuid, "points"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const topupMutation = useMutation({
    mutationFn: () => topupWallet(member!.id, Number(walletAmount)),
    onSuccess: () => {
      toast.success("Top-up berhasil");
      queryClient.invalidateQueries({ queryKey: ["wallet", member!.id] });
      queryClient.invalidateQueries({ queryKey: ["wallet", member!.id, "transactions"] });
      queryClient.invalidateQueries({ queryKey: ["members"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const withdrawMutation = useMutation({
    mutationFn: () => withdrawWallet(member!.id, Number(walletAmount)),
    onSuccess: () => {
      toast.success("Penarikan berhasil");
      queryClient.invalidateQueries({ queryKey: ["wallet", member!.id] });
      queryClient.invalidateQueries({ queryKey: ["wallet", member!.id, "transactions"] });
      queryClient.invalidateQueries({ queryKey: ["members"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const transferMutation = useMutation({
    mutationFn: () =>
      transferWallet(member!.id, Number(transferToId), Number(walletAmount)),
    onSuccess: () => {
      toast.success("Transfer wallet berhasil");
      queryClient.invalidateQueries({ queryKey: ["wallet"] });
      queryClient.invalidateQueries({ queryKey: ["members"] });
      onRefresh();
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  if (!member) return null;

  const tierColors: Record<string, string> = {
    bronze: "bg-amber-100 text-amber-800",
    silver: "bg-slate-200 text-slate-700",
    gold: "bg-yellow-100 text-yellow-800",
    platinum: "bg-violet-100 text-violet-800",
  };

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/40">
      <div className="flex h-full w-full max-w-lg flex-col bg-white shadow-xl">
        <div className="flex items-start justify-between border-b border-border p-6">
          <div>
            <h2 className="text-lg font-semibold">{member.name}</h2>
            <p className="text-sm text-muted-foreground">{member.member_code}</p>
            {member.tier && (
              <span
                className={`mt-2 inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                  tierColors[member.tier.slug] ?? "bg-slate-100"
                }`}
              >
                {member.tier.name}
              </span>
            )}
          </div>
          <div className="flex items-center gap-1">
            {onEdit && (
              <button
                type="button"
                onClick={() => onEdit(member)}
                className="rounded-lg p-1 hover:bg-slate-100"
                title="Edit member"
              >
                <Pencil className="h-5 w-5" />
              </button>
            )}
            <button type="button" onClick={onClose} className="rounded-lg p-1 hover:bg-slate-100">
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3 border-b border-border p-4">
          <div className="rounded-lg bg-violet-50 p-3">
            <p className="text-xs text-muted-foreground">Poin</p>
            <p className="text-xl font-bold text-violet-700">{pointBalance}</p>
          </div>
          <div className="rounded-lg bg-emerald-50 p-3">
            <p className="text-xs text-muted-foreground">Wallet</p>
            <p className="text-xl font-bold text-emerald-700">
              {formatCurrency(member.wallet?.balance ?? 0)}
            </p>
          </div>
        </div>

        <div className="flex border-b border-border">
          <button
            type="button"
            onClick={() => setTab("points")}
            className={`flex flex-1 items-center justify-center gap-2 py-3 text-sm font-medium ${
              tab === "points"
                ? "border-b-2 border-primary text-primary"
                : "text-muted-foreground"
            }`}
          >
            <Coins className="h-4 w-4" /> Poin
          </button>
          {hasWallet && (
            <button
              type="button"
              onClick={() => setTab("wallet")}
              className={`flex flex-1 items-center justify-center gap-2 py-3 text-sm font-medium ${
                tab === "wallet"
                  ? "border-b-2 border-primary text-primary"
                  : "text-muted-foreground"
              }`}
            >
              <Wallet className="h-4 w-4" /> Wallet
            </button>
          )}
        </div>

        <div className="flex-1 overflow-y-auto p-4">
          {tab === "points" ? (
            <div className="space-y-4">
              {pointsData?.config && (
                <div className="rounded-lg border border-violet-200 bg-violet-50 px-3 py-2 text-xs text-violet-800">
                  <p>
                    Dapat {pointsData.config.earn_points} poin per{" "}
                    {formatCurrency(pointsData.config.earn_amount)} belanja
                  </p>
                  <p>
                    Redeem {pointsData.config.redeem_points} poin ={" "}
                    {formatCurrency(pointsData.config.redeem_value)} · Min.{" "}
                    {pointsData.config.min_redeem_points} poin
                  </p>
                </div>
              )}

              {pointBalance <= 0 && (
                <div className="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-800">
                  Saldo poin kosong. Poin didapat otomatis dari transaksi POS (min.{" "}
                  {formatCurrency(pointsData?.config?.earn_amount ?? 10000)} ={" "}
                  {pointsData?.config?.earn_points ?? 1} poin).
                </div>
              )}

              <div className="space-y-2">
                <Label>Redeem Poin</Label>
                <div className="flex gap-2">
                  <Input
                    type="number"
                    min={minRedeem}
                    max={pointBalance > 0 ? pointBalance : undefined}
                    value={redeemPoints_}
                    onChange={(e) => setRedeemPoints(e.target.value)}
                    placeholder={`Min. ${minRedeem} poin`}
                  />
                  <Button
                    onClick={() => redeemMutation.mutate()}
                    isLoading={redeemMutation.isPending}
                    disabled={!canRedeem}
                  >
                    Redeem
                  </Button>
                </div>
                {redeemHint && (
                  <p className="text-xs text-muted-foreground">{redeemHint}</p>
                )}
              </div>

              <div className="space-y-2 rounded-lg border border-dashed border-border p-3">
                <Label>Tambah Poin Manual</Label>
                <div className="grid gap-2 sm:grid-cols-2">
                  <Input
                    type="number"
                    min={1}
                    value={adjustPoints_}
                    onChange={(e) => setAdjustPoints(e.target.value)}
                    placeholder="Jumlah poin"
                  />
                  <Input
                    value={adjustNote}
                    onChange={(e) => setAdjustNote(e.target.value)}
                    placeholder="Keterangan"
                  />
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => adjustMutation.mutate()}
                  isLoading={adjustMutation.isPending}
                  disabled={!adjustNote.trim() || Number(adjustPoints_) === 0}
                >
                  Tambah Poin
                </Button>
              </div>

              <div className="space-y-2">
                <p className="text-sm font-medium">Riwayat Poin</p>
                {(pointsData?.history ?? []).length === 0 ? (
                  <p className="text-sm text-muted-foreground">Belum ada riwayat</p>
                ) : (
                  pointsData?.history?.map((tx) => (
                    <div
                      key={tx.id}
                      className="flex justify-between rounded-lg border border-border px-3 py-2 text-sm"
                    >
                      <div>
                        <p className="font-medium capitalize">{tx.type}</p>
                        <p className="text-xs text-muted-foreground">
                          {tx.description ?? "—"}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className={tx.points > 0 ? "text-emerald-600" : "text-red-500"}>
                          {tx.points > 0 ? "+" : ""}{tx.points}
                        </p>
                        <p className="text-xs text-muted-foreground">
                          sisa {tx.balance_after}
                        </p>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="space-y-2">
                <Label>Jumlah (Rp)</Label>
                <Input
                  type="number"
                  value={walletAmount}
                  onChange={(e) => setWalletAmount(e.target.value)}
                />
              </div>
              <div className="flex gap-2">
                <Button
                  className="flex-1"
                  onClick={() => topupMutation.mutate()}
                  isLoading={topupMutation.isPending}
                >
                  Top-up
                </Button>
                <Button
                  variant="outline"
                  className="flex-1"
                  onClick={() => withdrawMutation.mutate()}
                  isLoading={withdrawMutation.isPending}
                >
                  Tarik
                </Button>
              </div>

              <div className="space-y-2 rounded-lg border border-dashed border-border p-3">
                <Label>Transfer ke Member Lain</Label>
                <select
                  value={transferToId}
                  onChange={(e) =>
                    setTransferToId(e.target.value ? Number(e.target.value) : "")
                  }
                  className="flex h-10 w-full rounded-lg border border-border bg-white px-3 text-sm"
                >
                  <option value="">Pilih penerima</option>
                  {(allMembers?.data ?? [])
                    .filter((m) => m.id !== member.id)
                    .map((m) => (
                      <option key={m.id} value={m.id}>
                        {m.name} ({m.member_code})
                      </option>
                    ))}
                </select>
                <Button
                  variant="outline"
                  size="sm"
                  className="w-full"
                  disabled={!transferToId || Number(walletAmount) <= 0}
                  onClick={() => transferMutation.mutate()}
                  isLoading={transferMutation.isPending}
                >
                  Transfer
                </Button>
              </div>

              <div className="space-y-2">
                <p className="text-sm font-medium">Riwayat Wallet</p>
                {(walletTx?.data ?? []).length === 0 ? (
                  <p className="text-sm text-muted-foreground">Belum ada riwayat</p>
                ) : (
                  walletTx?.data.map((tx) => (
                    <div
                      key={tx.id}
                      className="flex justify-between rounded-lg border border-border px-3 py-2 text-sm"
                    >
                      <div>
                        <p className="font-medium capitalize">{tx.type.replace("_", " ")}</p>
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
                      <p className="font-semibold">{formatCurrency(tx.amount)}</p>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>

        <div className="border-t border-border p-4 text-xs text-muted-foreground">
          <p>Total belanja: {formatCurrency(member.total_spend)}</p>
          <p>Kunjungan: {member.visit_count}x</p>
          <p>Telepon: {member.phone}</p>
        </div>
      </div>
    </div>
  );
}