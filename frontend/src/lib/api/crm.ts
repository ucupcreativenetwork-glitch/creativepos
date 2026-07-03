import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type {
  AssignTicketPayload,
  CreateTicketPayload,
  Faq,
  PaginatedMeta,
  ReplyTicketPayload,
  SupportTicket,
  UpdateTicketStatusPayload,
} from "@/types/crm";

interface PaginatedResponse<T> {
  data: T[];
  meta: PaginatedMeta;
}

function defaultMeta(count: number): PaginatedMeta {
  return {
    current_page: 1,
    per_page: count,
    total: count,
    last_page: 1,
  };
}

export async function getTickets(params?: {
  status?: string;
  priority?: string;
  search?: string;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<SupportTicket>> {
  const { data } = await apiClient.get<
    ApiResponse<SupportTicket[]> & { meta?: PaginatedMeta }
  >("/crm/tickets", { params });

  return {
    data: data.data,
    meta: data.meta ?? defaultMeta(data.data.length),
  };
}

export async function getTicket(id: string | number): Promise<SupportTicket> {
  const { data } = await apiClient.get<ApiResponse<SupportTicket>>(
    `/crm/tickets/${id}`
  );
  return data.data;
}

export async function createTicket(
  payload: CreateTicketPayload
): Promise<SupportTicket> {
  const { data } = await apiClient.post<ApiResponse<SupportTicket>>(
    "/crm/tickets",
    payload
  );
  return data.data;
}

export async function replyToTicket(
  id: string | number,
  payload: ReplyTicketPayload
): Promise<SupportTicket> {
  const { data } = await apiClient.post<ApiResponse<SupportTicket>>(
    `/crm/tickets/${id}/messages`,
    payload
  );
  return data.data;
}

export async function updateTicketStatus(
  id: string | number,
  payload: UpdateTicketStatusPayload
): Promise<SupportTicket> {
  const { data } = await apiClient.patch<ApiResponse<SupportTicket>>(
    `/crm/tickets/${id}/status`,
    payload
  );
  return data.data;
}

export async function assignTicket(
  id: string | number,
  payload: AssignTicketPayload
): Promise<SupportTicket> {
  const { data } = await apiClient.patch<ApiResponse<SupportTicket>>(
    `/crm/tickets/${id}/assign`,
    payload
  );
  return data.data;
}

export async function getFaqs(): Promise<Faq[]> {
  const { data } = await apiClient.get<ApiResponse<Faq[]>>("/crm/faqs");
  return data.data;
}