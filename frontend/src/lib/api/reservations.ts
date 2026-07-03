import { apiClient } from "@/lib/api/client";
import type { ApiResponse } from "@/types/auth";
import type { PaginatedMeta } from "@/types/loyalty";
import type {
  CalendarDay,
  Reservation,
  ReservationPayload,
  TimeSlot,
} from "@/types/reservation";

interface PaginatedResponse<T> {
  data: T[];
  meta: PaginatedMeta;
}

export async function getReservations(params?: {
  outlet_id?: number;
  status?: string;
  date?: string;
  date_from?: string;
  date_to?: string;
  search?: string;
  page?: number;
  per_page?: number;
}): Promise<PaginatedResponse<Reservation>> {
  const { data } = await apiClient.get<
    ApiResponse<Reservation[]> & { meta?: PaginatedMeta }
  >("/reservations", { params });

  return {
    data: data.data,
    meta: data.meta ?? {
      current_page: 1,
      per_page: data.data.length,
      total: data.data.length,
      last_page: 1,
    },
  };
}

export async function getReservation(uuid: string): Promise<Reservation> {
  const { data } = await apiClient.get<ApiResponse<Reservation>>(
    `/reservations/${uuid}`
  );
  return data.data;
}

export async function createReservation(
  payload: ReservationPayload
): Promise<Reservation> {
  const { data } = await apiClient.post<ApiResponse<Reservation>>(
    "/reservations",
    payload
  );
  return data.data;
}

export async function updateReservation(
  uuid: string,
  payload: Partial<ReservationPayload>
): Promise<Reservation> {
  const { data } = await apiClient.put<ApiResponse<Reservation>>(
    `/reservations/${uuid}`,
    payload
  );
  return data.data;
}

export async function updateReservationStatus(
  uuid: string,
  status: string
): Promise<Reservation> {
  const { data } = await apiClient.patch<ApiResponse<Reservation>>(
    `/reservations/${uuid}/status`,
    { status }
  );
  return data.data;
}

export async function getReservationCalendar(params?: {
  outlet_id?: number;
  date_from?: string;
  date_to?: string;
}): Promise<CalendarDay[]> {
  const { data } = await apiClient.get<ApiResponse<CalendarDay[]>>(
    "/reservations/calendar",
    { params }
  );
  return data.data;
}

export async function getReservationSlots(params: {
  outlet_id: number;
  date: string;
  guest_count?: number;
}): Promise<TimeSlot[]> {
  const { data } = await apiClient.get<ApiResponse<TimeSlot[]>>(
    "/reservations/slots",
    { params }
  );
  return data.data;
}

export interface ReservationTimeSlotConfig {
  id: number;
  outlet_id: number;
  day_of_week: number;
  start_time: string;
  end_time: string;
  capacity: number;
  is_active: boolean;
}

export async function getTimeSlotConfigs(params?: {
  outlet_id?: number;
}): Promise<ReservationTimeSlotConfig[]> {
  const { data } = await apiClient.get<ApiResponse<ReservationTimeSlotConfig[]>>(
    "/reservations/time-slots",
    { params }
  );
  return data.data;
}

export async function createTimeSlotConfig(payload: {
  outlet_id: number;
  day_of_week: number;
  start_time: string;
  end_time: string;
  capacity: number;
  is_active?: boolean;
}): Promise<ReservationTimeSlotConfig> {
  const { data } = await apiClient.post<ApiResponse<ReservationTimeSlotConfig>>(
    "/reservations/time-slots",
    payload
  );
  return data.data;
}

export async function updateTimeSlotConfig(
  id: number,
  payload: Partial<{
    day_of_week: number;
    start_time: string;
    end_time: string;
    capacity: number;
    is_active: boolean;
  }>
): Promise<ReservationTimeSlotConfig> {
  const { data } = await apiClient.put<ApiResponse<ReservationTimeSlotConfig>>(
    `/reservations/time-slots/${id}`,
    payload
  );
  return data.data;
}

export async function deleteTimeSlotConfig(id: number): Promise<void> {
  await apiClient.delete(`/reservations/time-slots/${id}`);
}