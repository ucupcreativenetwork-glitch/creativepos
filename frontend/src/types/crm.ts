export type TicketStatus =
  | "open"
  | "assigned"
  | "pending"
  | "resolved"
  | "closed";

export type TicketPriority = "low" | "medium" | "high" | "critical";

export type TicketChannel =
  | "whatsapp"
  | "telegram"
  | "email"
  | "website"
  | "phone";

export type MessageSenderType = "customer" | "agent" | "system";

export interface TicketAssignee {
  id: number;
  name: string;
  email?: string;
}

export interface TicketMessage {
  id: number;
  ticket_id: number;
  sender_type: MessageSenderType;
  sender_id?: number | null;
  sender_name?: string | null;
  message: string;
  attachments?: string[] | null;
  is_internal: boolean;
  created_at: string;
}

export interface SupportTicket {
  id: number;
  uuid: string;
  ticket_number: string;
  subject: string;
  priority: TicketPriority;
  status: TicketStatus;
  channel?: TicketChannel;
  customer_name?: string | null;
  customer_email?: string | null;
  customer_phone?: string | null;
  assigned_to?: number | null;
  assignee?: TicketAssignee | null;
  sla_deadline?: string | null;
  first_response_at?: string | null;
  resolved_at?: string | null;
  closed_at?: string | null;
  messages?: TicketMessage[];
  messages_count?: number;
  created_at: string;
  updated_at?: string;
}

export interface CreateTicketPayload {
  subject: string;
  message: string;
  priority?: TicketPriority;
  channel?: TicketChannel;
  customer_name?: string;
  customer_email?: string;
  customer_phone?: string;
}

export interface ReplyTicketPayload {
  message: string;
  is_internal?: boolean;
}

export interface UpdateTicketStatusPayload {
  status: TicketStatus;
}

export interface AssignTicketPayload {
  assigned_to: number;
}

export interface Faq {
  id: number;
  question: string;
  answer: string;
  sort_order: number;
  is_active: boolean;
}

export interface PaginatedMeta {
  current_page: number;
  per_page: number;
  total: number;
  last_page: number;
}