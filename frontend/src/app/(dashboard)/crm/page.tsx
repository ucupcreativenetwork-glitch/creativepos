"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  ChevronDown,
  Headphones,
  MessageSquare,
  Plus,
  Search,
  Send,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getErrorMessage } from "@/lib/api/client";
import {
  assignTicket,
  createTicket,
  getFaqs,
  getTicket,
  getTickets,
  replyToTicket,
  updateTicketStatus,
} from "@/lib/api/crm";
import { getSettingsUsers } from "@/lib/api/settings";
import { formatDate } from "@/lib/utils/format";
import type {
  SupportTicket,
  TicketPriority,
  TicketStatus,
} from "@/types/crm";

const statusLabels: Record<TicketStatus, string> = {
  open: "Terbuka",
  assigned: "Ditugaskan",
  pending: "Menunggu",
  resolved: "Selesai",
  closed: "Ditutup",
};

const statusColors: Record<TicketStatus, string> = {
  open: "bg-blue-50 text-blue-700",
  assigned: "bg-violet-50 text-violet-700",
  pending: "bg-amber-50 text-amber-700",
  resolved: "bg-emerald-50 text-emerald-700",
  closed: "bg-slate-100 text-slate-600",
};

const priorityLabels: Record<TicketPriority, string> = {
  low: "Rendah",
  medium: "Sedang",
  high: "Tinggi",
  critical: "Kritis",
};

const priorityColors: Record<TicketPriority, string> = {
  low: "bg-slate-100 text-slate-600",
  medium: "bg-sky-50 text-sky-700",
  high: "bg-orange-50 text-orange-700",
  critical: "bg-rose-50 text-rose-700",
};

export default function CrmPage() {
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<"tickets" | "faq">("tickets");
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("");
  const [page, setPage] = useState(1);
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(
    null
  );
  const [createOpen, setCreateOpen] = useState(false);
  const [replyText, setReplyText] = useState("");
  const [expandedFaq, setExpandedFaq] = useState<number | null>(null);

  const [newSubject, setNewSubject] = useState("");
  const [newMessage, setNewMessage] = useState("");
  const [newPriority, setNewPriority] = useState<TicketPriority>("medium");
  const [newCustomerName, setNewCustomerName] = useState("");
  const [newCustomerPhone, setNewCustomerPhone] = useState("");
  const [assignUserId, setAssignUserId] = useState<number | "">("");

  const { data: ticketsData, isLoading: ticketsLoading } = useQuery({
    queryKey: ["crm", "tickets", search, statusFilter, page],
    queryFn: () =>
      getTickets({
        search: search || undefined,
        status: statusFilter || undefined,
        page,
        per_page: 15,
      }),
    staleTime: 30 * 1000,
    enabled: tab === "tickets",
  });

  const { data: ticketDetail, isLoading: detailLoading } = useQuery({
    queryKey: ["crm", "ticket", selectedTicket?.uuid],
    queryFn: () => getTicket(selectedTicket!.uuid),
    enabled: !!selectedTicket,
    staleTime: 15 * 1000,
  });

  const { data: faqs = [], isLoading: faqsLoading } = useQuery({
    queryKey: ["crm", "faqs"],
    queryFn: getFaqs,
    staleTime: 5 * 60 * 1000,
    enabled: tab === "faq",
  });

  const createMutation = useMutation({
    mutationFn: () =>
      createTicket({
        subject: newSubject,
        message: newMessage,
        priority: newPriority,
        customer_name: newCustomerName || undefined,
        customer_phone: newCustomerPhone || undefined,
        channel: "website",
      }),
    onSuccess: (ticket) => {
      toast.success("Tiket berhasil dibuat");
      setCreateOpen(false);
      setNewSubject("");
      setNewMessage("");
      setNewCustomerName("");
      setNewCustomerPhone("");
      queryClient.invalidateQueries({ queryKey: ["crm"] });
      setSelectedTicket(ticket);
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const replyMutation = useMutation({
    mutationFn: () =>
      replyToTicket(selectedTicket!.uuid, { message: replyText }),
    onSuccess: () => {
      toast.success("Balasan terkirim");
      setReplyText("");
      queryClient.invalidateQueries({ queryKey: ["crm"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const statusMutation = useMutation({
    mutationFn: (status: TicketStatus) =>
      updateTicketStatus(selectedTicket!.uuid, { status }),
    onSuccess: () => {
      toast.success("Status tiket diperbarui");
      queryClient.invalidateQueries({ queryKey: ["crm"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const { data: staffData } = useQuery({
    queryKey: ["settings", "users"],
    queryFn: () => getSettingsUsers({ per_page: 50 }),
    staleTime: 5 * 60 * 1000,
    enabled: !!selectedTicket,
  });

  const assignMutation = useMutation({
    mutationFn: (userId: number) =>
      assignTicket(selectedTicket!.uuid, { assigned_to: userId }),
    onSuccess: () => {
      toast.success("Tiket berhasil ditugaskan");
      setAssignUserId("");
      queryClient.invalidateQueries({ queryKey: ["crm"] });
    },
    onError: (e) => toast.error(getErrorMessage(e)),
  });

  const tickets = ticketsData?.data ?? [];
  const meta = ticketsData?.meta;
  const activeTicket = ticketDetail ?? selectedTicket;

  return (
    <div className="space-y-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">CRM & Dukungan</h1>
          <p className="mt-1 text-muted-foreground">
            Kelola tiket pelanggan dan basis pengetahuan
          </p>
        </div>
        {tab === "tickets" && (
          <Button onClick={() => setCreateOpen(true)}>
            <Plus className="h-4 w-4" />
            Buat Tiket
          </Button>
        )}
      </div>

      <div className="flex gap-2 border-b border-border">
        <button
          type="button"
          onClick={() => setTab("tickets")}
          className={`flex items-center gap-2 border-b-2 px-4 py-2.5 text-sm font-medium transition-colors ${
            tab === "tickets"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          <Headphones className="h-4 w-4" />
          Tiket
        </button>
        <button
          type="button"
          onClick={() => setTab("faq")}
          className={`flex items-center gap-2 border-b-2 px-4 py-2.5 text-sm font-medium transition-colors ${
            tab === "faq"
              ? "border-primary text-primary"
              : "border-transparent text-muted-foreground hover:text-foreground"
          }`}
        >
          <MessageSquare className="h-4 w-4" />
          FAQ
        </button>
      </div>

      {tab === "tickets" ? (
        <div className="grid gap-6 lg:grid-cols-5">
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle className="text-base">Kotak Masuk Tiket</CardTitle>
              <CardDescription>
                {meta ? `${meta.total} tiket` : "Memuat..."}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Cari tiket..."
                  value={search}
                  onChange={(e) => {
                    setSearch(e.target.value);
                    setPage(1);
                  }}
                  className="pl-9"
                />
              </div>

              <select
                value={statusFilter}
                onChange={(e) => {
                  setStatusFilter(e.target.value);
                  setPage(1);
                }}
                className="h-9 w-full rounded-lg border border-border bg-white px-3 text-sm"
              >
                <option value="">Semua Status</option>
                {Object.entries(statusLabels).map(([value, label]) => (
                  <option key={value} value={value}>
                    {label}
                  </option>
                ))}
              </select>

              {ticketsLoading ? (
                <div className="space-y-2">
                  {Array.from({ length: 5 }).map((_, i) => (
                    <div
                      key={i}
                      className="h-16 animate-pulse rounded-lg bg-slate-100"
                    />
                  ))}
                </div>
              ) : tickets.length === 0 ? (
                <div className="flex flex-col items-center py-10 text-center">
                  <Headphones className="mb-3 h-10 w-10 text-muted-foreground" />
                  <p className="font-medium">Belum ada tiket</p>
                </div>
              ) : (
                <div className="max-h-[520px] space-y-2 overflow-y-auto">
                  {tickets.map((ticket) => (
                    <button
                      key={ticket.uuid}
                      type="button"
                      onClick={() => setSelectedTicket(ticket)}
                      className={`w-full rounded-lg border p-3 text-left transition-colors ${
                        selectedTicket?.uuid === ticket.uuid
                          ? "border-primary bg-primary/5"
                          : "border-border hover:bg-slate-50"
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <p className="line-clamp-1 text-sm font-medium">
                          {ticket.subject}
                        </p>
                        <span
                          className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-medium ${
                            priorityColors[ticket.priority]
                          }`}
                        >
                          {priorityLabels[ticket.priority]}
                        </span>
                      </div>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {ticket.ticket_number}
                      </p>
                      <div className="mt-2 flex items-center gap-2">
                        <span
                          className={`rounded-full px-2 py-0.5 text-[10px] font-medium ${
                            statusColors[ticket.status]
                          }`}
                        >
                          {statusLabels[ticket.status]}
                        </span>
                        <span className="text-[10px] text-muted-foreground">
                          {formatDate(ticket.created_at, {
                            day: "numeric",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                        </span>
                      </div>
                    </button>
                  ))}
                </div>
              )}

              {meta && meta.last_page > 1 && (
                <div className="flex items-center justify-between pt-2">
                  <p className="text-xs text-muted-foreground">
                    Hal. {meta.current_page}/{meta.last_page}
                  </p>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={page <= 1}
                      onClick={() => setPage((p) => p - 1)}
                    >
                      Prev
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={page >= meta.last_page}
                      onClick={() => setPage((p) => p + 1)}
                    >
                      Next
                    </Button>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card className="lg:col-span-3">
            <CardHeader>
              <CardTitle className="text-base">Detail Tiket</CardTitle>
            </CardHeader>
            <CardContent>
              {!activeTicket ? (
                <div className="flex h-64 flex-col items-center justify-center text-center text-muted-foreground">
                  <MessageSquare className="mb-3 h-10 w-10 opacity-50" />
                  <p>Pilih tiket untuk melihat detail</p>
                </div>
              ) : detailLoading ? (
                <div className="flex h-64 items-center justify-center">
                  <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
                </div>
              ) : (
                <div className="space-y-4">
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div>
                      <h3 className="font-semibold">{activeTicket.subject}</h3>
                      <p className="text-sm text-muted-foreground">
                        {activeTicket.ticket_number}
                        {activeTicket.customer_name &&
                          ` · ${activeTicket.customer_name}`}
                      </p>
                    </div>
                    <div className="flex flex-wrap gap-2">
                      <span
                        className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                          statusColors[activeTicket.status]
                        }`}
                      >
                        {statusLabels[activeTicket.status]}
                      </span>
                      <span
                        className={`rounded-full px-2.5 py-1 text-xs font-medium ${
                          priorityColors[activeTicket.priority]
                        }`}
                      >
                        {priorityLabels[activeTicket.priority]}
                      </span>
                    </div>
                  </div>

                  {activeTicket.status !== "closed" && (
                    <div className="flex flex-wrap gap-2">
                      {activeTicket.status !== "assigned" && (
                        <div className="flex flex-wrap items-center gap-2">
                          <select
                            value={assignUserId}
                            onChange={(e) =>
                              setAssignUserId(
                                e.target.value ? Number(e.target.value) : ""
                              )
                            }
                            className="h-9 rounded-lg border border-border bg-white px-2 text-sm"
                          >
                            <option value="">Pilih staff...</option>
                            {(staffData?.data ?? []).map((user) => (
                              <option key={user.id} value={user.id}>
                                {user.name}
                              </option>
                            ))}
                          </select>
                          <Button
                            variant="outline"
                            size="sm"
                            disabled={!assignUserId}
                            onClick={() => assignMutation.mutate(Number(assignUserId))}
                            isLoading={assignMutation.isPending}
                          >
                            Tugaskan
                          </Button>
                        </div>
                      )}
                      {activeTicket.status !== "resolved" && (
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => statusMutation.mutate("resolved")}
                          isLoading={statusMutation.isPending}
                        >
                          Selesaikan
                        </Button>
                      )}
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => statusMutation.mutate("closed")}
                        isLoading={statusMutation.isPending}
                      >
                        Tutup
                      </Button>
                    </div>
                  )}

                  <div className="max-h-72 space-y-3 overflow-y-auto rounded-lg border border-border bg-slate-50/50 p-4">
                    {(activeTicket.messages ?? []).length === 0 ? (
                      <p className="text-center text-sm text-muted-foreground">
                        Belum ada pesan
                      </p>
                    ) : (
                      (activeTicket.messages ?? []).map((msg) => (
                        <div
                          key={msg.id}
                          className={`rounded-lg p-3 text-sm ${
                            msg.sender_type === "agent"
                              ? "ml-8 bg-primary/10"
                              : msg.sender_type === "system"
                                ? "bg-slate-100 text-center text-xs text-muted-foreground"
                                : "mr-8 bg-white shadow-sm"
                          }`}
                        >
                          {msg.sender_type !== "system" && (
                            <p className="mb-1 text-xs font-medium text-muted-foreground">
                              {msg.sender_name ??
                                (msg.sender_type === "agent"
                                  ? "Agen"
                                  : "Pelanggan")}
                            </p>
                          )}
                          <p className="whitespace-pre-wrap">{msg.message}</p>
                          <p className="mt-1 text-[10px] text-muted-foreground">
                            {formatDate(msg.created_at, {
                              day: "numeric",
                              month: "short",
                              hour: "2-digit",
                              minute: "2-digit",
                            })}
                          </p>
                        </div>
                      ))
                    )}
                  </div>

                  {activeTicket.status !== "closed" && (
                    <div className="flex gap-2">
                      <Input
                        placeholder="Tulis balasan..."
                        value={replyText}
                        onChange={(e) => setReplyText(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === "Enter" && !e.shiftKey && replyText.trim()) {
                            e.preventDefault();
                            replyMutation.mutate();
                          }
                        }}
                      />
                      <Button
                        onClick={() => replyMutation.mutate()}
                        disabled={!replyText.trim()}
                        isLoading={replyMutation.isPending}
                      >
                        <Send className="h-4 w-4" />
                      </Button>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Pertanyaan Umum (FAQ)</CardTitle>
            <CardDescription>
              Jawaban untuk pertanyaan yang sering diajukan
            </CardDescription>
          </CardHeader>
          <CardContent>
            {faqsLoading ? (
              <div className="space-y-3">
                {Array.from({ length: 4 }).map((_, i) => (
                  <div
                    key={i}
                    className="h-14 animate-pulse rounded-lg bg-slate-100"
                  />
                ))}
              </div>
            ) : faqs.length === 0 ? (
              <div className="py-12 text-center text-muted-foreground">
                Belum ada FAQ
              </div>
            ) : (
              <div className="space-y-2">
                {faqs.map((faq) => (
                  <div
                    key={faq.id}
                    className="rounded-lg border border-border"
                  >
                    <button
                      type="button"
                      onClick={() =>
                        setExpandedFaq(expandedFaq === faq.id ? null : faq.id)
                      }
                      className="flex w-full items-center justify-between px-4 py-3 text-left text-sm font-medium hover:bg-slate-50"
                    >
                      {faq.question}
                      <ChevronDown
                        className={`h-4 w-4 shrink-0 text-muted-foreground transition-transform ${
                          expandedFaq === faq.id ? "rotate-180" : ""
                        }`}
                      />
                    </button>
                    {expandedFaq === faq.id && (
                      <div className="border-t border-border px-4 py-3 text-sm text-muted-foreground">
                        {faq.answer}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {createOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-lg rounded-xl bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold">Buat Tiket Baru</h2>
              <button
                type="button"
                onClick={() => setCreateOpen(false)}
                className="rounded-lg p-1 hover:bg-slate-100"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <Label htmlFor="subject">Subjek</Label>
                <Input
                  id="subject"
                  value={newSubject}
                  onChange={(e) => setNewSubject(e.target.value)}
                  placeholder="Masalah atau pertanyaan"
                />
              </div>
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <Label htmlFor="customerName">Nama Pelanggan</Label>
                  <Input
                    id="customerName"
                    value={newCustomerName}
                    onChange={(e) => setNewCustomerName(e.target.value)}
                  />
                </div>
                <div>
                  <Label htmlFor="customerPhone">Telepon</Label>
                  <Input
                    id="customerPhone"
                    value={newCustomerPhone}
                    onChange={(e) => setNewCustomerPhone(e.target.value)}
                  />
                </div>
              </div>
              <div>
                <Label htmlFor="priority">Prioritas</Label>
                <select
                  id="priority"
                  value={newPriority}
                  onChange={(e) =>
                    setNewPriority(e.target.value as TicketPriority)
                  }
                  className="h-10 w-full rounded-lg border border-border px-3 text-sm"
                >
                  {Object.entries(priorityLabels).map(([value, label]) => (
                    <option key={value} value={value}>
                      {label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <Label htmlFor="message">Pesan</Label>
                <textarea
                  id="message"
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  rows={4}
                  className="w-full rounded-lg border border-border px-3 py-2 text-sm focus:border-primary focus:outline-none focus:ring-2 focus:ring-primary/20"
                  placeholder="Jelaskan masalah secara detail..."
                />
              </div>
              <div className="flex justify-end gap-2">
                <Button variant="outline" onClick={() => setCreateOpen(false)}>
                  Batal
                </Button>
                <Button
                  onClick={() => createMutation.mutate()}
                  disabled={!newSubject.trim() || !newMessage.trim()}
                  isLoading={createMutation.isPending}
                >
                  Buat Tiket
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}