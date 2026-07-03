export type ReservationStatus =
  | "pending"
  | "confirmed"
  | "arrived"
  | "completed"
  | "cancelled"
  | "no_show";

export interface Reservation {
  id: number;
  uuid: string;
  reservation_number: string;
  outlet_id: number;
  outlet?: { id: number; name: string; code: string } | null;
  member_id?: number | null;
  table_id?: number | null;
  table?: { id: number; table_number: string; name?: string | null } | null;
  customer_name: string;
  customer_phone: string;
  customer_email?: string | null;
  guest_count: number;
  reservation_date: string;
  reservation_time: string;
  status: ReservationStatus;
  notes?: string | null;
  confirmed_at?: string | null;
  arrived_at?: string | null;
  cancelled_at?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface TimeSlot {
  time: string;
  available: boolean;
  capacity: number;
  booked_count: number;
}

export interface CalendarDay {
  date: string;
  count: number;
  reservations?: Pick<
    Reservation,
    "uuid" | "reservation_number" | "customer_name" | "reservation_time" | "guest_count" | "status"
  >[];
}

export interface ReservationPayload {
  outlet_id: number;
  customer_name: string;
  customer_phone: string;
  customer_email?: string;
  guest_count: number;
  reservation_date: string;
  reservation_time: string;
  notes?: string;
  table_id?: number;
  member_id?: number;
}