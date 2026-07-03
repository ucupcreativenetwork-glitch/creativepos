export type DeliveryStatus =
  | "waiting"
  | "processing"
  | "cooking"
  | "ready"
  | "delivering"
  | "completed"
  | "cancelled";

export interface DeliveryAddress {
  id?: number;
  label?: string;
  recipient_name: string;
  phone: string;
  address: string;
  latitude?: number | null;
  longitude?: number | null;
}

export interface DeliveryOrderItem {
  id: number;
  product_id: number;
  product_name: string;
  quantity: number;
  unit_price: number;
  subtotal: number;
  notes?: string | null;
}

export interface DeliveryDriver {
  id: number;
  name: string;
  phone: string;
  type: "internal" | "external";
  vehicle_type?: string | null;
  vehicle_number?: string | null;
  is_available: boolean;
  current_latitude?: number | null;
  current_longitude?: number | null;
}

export interface DeliveryZone {
  id: number;
  name: string;
  outlet_id?: number;
  base_fee: number;
  fee_per_km?: number;
  max_distance_km?: number;
  is_active: boolean;
}

export interface FeeCalculation {
  zone_id: number;
  zone_name?: string;
  distance_km: number;
  shipping_fee: number;
  estimated_minutes?: number;
}

export interface DeliveryOrder {
  id: number;
  uuid: string;
  delivery_number: string;
  outlet_id: number;
  outlet?: { id: number; name: string; code: string } | null;
  order_id?: number | null;
  driver_id?: number | null;
  driver?: DeliveryDriver | null;
  address?: DeliveryAddress | null;
  delivery_address?: string | null;
  customer_name: string;
  customer_phone: string;
  status: DeliveryStatus;
  shipping_fee: number;
  distance_km?: number | null;
  estimated_minutes?: number | null;
  subtotal?: number;
  grand_total?: number;
  items?: DeliveryOrderItem[];
  assigned_at?: string | null;
  picked_up_at?: string | null;
  delivered_at?: string | null;
  created_at?: string;
  updated_at?: string;
}

export interface CreateDeliveryOrderPayload {
  outlet_id: number;
  customer_name: string;
  customer_phone: string;
  zone_id?: number;
  distance_km?: number;
  shipping_fee?: number;
  estimated_minutes?: number;
  address: Omit<DeliveryAddress, "id">;
  items: { product_id: number; quantity: number; notes?: string }[];
  notes?: string;
}

export interface CalculateFeePayload {
  outlet_id?: number;
  zone_id: number;
  distance_km: number;
  address?: string;
}