"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { Crown, Plus, Search, Users } from "lucide-react";
import { MemberDetailPanel } from "@/components/members/member-detail-panel";
import { MemberFormDialog } from "@/components/members/member-form-dialog";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { getMembers, getTiers } from "@/lib/api/members";
import { formatCurrency } from "@/lib/utils/format";
import type { Member } from "@/types/loyalty";

export default function MembersPage() {
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [formOpen, setFormOpen] = useState(false);
  const [editingMember, setEditingMember] = useState<Member | null>(null);
  const [selectedMember, setSelectedMember] = useState<Member | null>(null);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["members", search, page],
    queryFn: () => getMembers({ search: search || undefined, page, per_page: 10 }),
    staleTime: 30 * 1000,
  });

  const { data: tiers = [] } = useQuery({
    queryKey: ["members", "tiers"],
    queryFn: getTiers,
    staleTime: 5 * 60 * 1000,
  });

  const members = data?.data ?? [];
  const meta = data?.meta;

  const tierColors: Record<string, string> = {
    bronze: "bg-amber-50 text-amber-700",
    silver: "bg-slate-100 text-slate-600",
    gold: "bg-yellow-50 text-yellow-700",
    platinum: "bg-violet-50 text-violet-700",
  };

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Member & Loyalty</h1>
          <p className="mt-1 text-muted-foreground">
            Kelola member, poin loyalitas, dan wallet
          </p>
        </div>
        <Button
          onClick={() => {
            setEditingMember(null);
            setFormOpen(true);
          }}
        >
          <Plus className="h-4 w-4" />
          Tambah Member
        </Button>
      </div>

      {tiers.length > 0 && (
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          {tiers.map((tier) => (
            <Card key={tier.id} className="border-dashed">
              <CardContent className="flex items-center gap-3 p-4">
                <div className={`rounded-lg p-2 ${tierColors[tier.slug] ?? "bg-slate-50"}`}>
                  <Crown className="h-4 w-4" />
                </div>
                <div>
                  <p className="text-sm font-semibold">{tier.name}</p>
                  <p className="text-xs text-muted-foreground">
                    Min. {formatCurrency(tier.min_spend)} · {tier.point_multiplier}x poin
                  </p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Daftar Member</CardTitle>
          <CardDescription>
            {meta ? `${meta.total} member terdaftar` : "Memuat..."}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Cari nama, kode, atau telepon..."
              value={search}
              onChange={(e) => {
                setSearch(e.target.value);
                setPage(1);
              }}
              className="pl-9"
            />
          </div>

          {isLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 5 }).map((_, i) => (
                <div key={i} className="h-14 animate-pulse rounded-lg bg-slate-100" />
              ))}
            </div>
          ) : members.length === 0 ? (
            <div className="flex flex-col items-center py-12 text-center">
              <Users className="mb-3 h-10 w-10 text-muted-foreground" />
              <p className="font-medium">Belum ada member</p>
            </div>
          ) : (
            <div className="overflow-x-auto rounded-lg border border-border">
              <table className="w-full text-sm">
                <thead className="bg-slate-50 text-left text-xs text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-medium">Member</th>
                    <th className="px-4 py-3 font-medium">Kode</th>
                    <th className="px-4 py-3 font-medium">Tier</th>
                    <th className="px-4 py-3 font-medium text-right">Poin</th>
                    <th className="px-4 py-3 font-medium text-right">Wallet</th>
                    <th className="px-4 py-3 font-medium text-center">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {members.map((member) => (
                    <tr
                      key={member.uuid}
                      className="cursor-pointer hover:bg-slate-50/50"
                      onClick={() => setSelectedMember(member)}
                    >
                      <td className="px-4 py-3">
                        <p className="font-medium">{member.name}</p>
                        <p className="text-xs text-muted-foreground">{member.phone}</p>
                      </td>
                      <td className="px-4 py-3 text-muted-foreground">
                        {member.member_code}
                      </td>
                      <td className="px-4 py-3">
                        {member.tier ? (
                          <span
                            className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                              tierColors[member.tier.slug] ?? "bg-slate-100"
                            }`}
                          >
                            {member.tier.name}
                          </span>
                        ) : (
                          "—"
                        )}
                      </td>
                      <td className="px-4 py-3 text-right font-medium text-violet-600">
                        {member.points?.balance ?? 0}
                      </td>
                      <td className="px-4 py-3 text-right">
                        {formatCurrency(member.wallet?.balance ?? 0)}
                      </td>
                      <td className="px-4 py-3 text-center">
                        <span
                          className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${
                            member.status === "active"
                              ? "bg-emerald-50 text-emerald-700"
                              : "bg-slate-100 text-slate-600"
                          }`}
                        >
                          {member.status}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {meta && meta.last_page > 1 && (
            <div className="flex items-center justify-between">
              <p className="text-sm text-muted-foreground">
                Halaman {meta.current_page} dari {meta.last_page}
              </p>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page <= 1}
                  onClick={() => setPage((p) => p - 1)}
                >
                  Sebelumnya
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page >= meta.last_page}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Berikutnya
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <MemberFormDialog
        open={formOpen}
        onClose={() => {
          setFormOpen(false);
          setEditingMember(null);
        }}
        onSuccess={() => refetch()}
        member={editingMember}
      />

      <MemberDetailPanel
        member={selectedMember}
        onClose={() => setSelectedMember(null)}
        onRefresh={() => refetch()}
        onEdit={(m) => {
          setEditingMember(m);
          setFormOpen(true);
        }}
      />
    </div>
  );
}