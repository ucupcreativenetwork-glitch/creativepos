export interface ProductModifier {
  id: number;
  name: string;
  price_adjustment: number;
  is_default?: boolean;
  sort_order?: number;
}

export interface ProductModifierGroup {
  id: number;
  name: string;
  is_required: boolean;
  min_select: number;
  max_select: number;
  sort_order?: number;
  modifiers: ProductModifier[];
}

export interface PosProduct {
  id: number;
  uuid: string;
  name: string;
  image_url?: string | null;
  sku: string;
  barcode?: string | null;
  base_price: number;
  category?: { id: number; name: string } | null;
  total_stock: number;
  track_stock: boolean;
  modifier_groups?: ProductModifierGroup[];
}

export interface PosCategory {
  id: number;
  uuid: string;
  name: string;
}

export interface PaymentMethod {
  id: number;
  code: string;
  name: string;
  type: string;
}

export interface Shift {
  id: number;
  shift_number: string;
  status: "open" | "closed";
  opening_cash: number;
  closing_cash?: number | null;
  expected_cash?: number | null;
  cash_difference?: number | null;
  total_sales: number;
  total_transactions: number;
  outlet?: { id: number; name: string; code: string };
  cashier?: { id: number; name: string };
  opened_at?: string;
  closed_at?: string | null;
  notes?: string | null;
}

export interface SelectedModifier {
  modifier_id: number;
  group_id: number;
  group_name: string;
  name: string;
  price_adjustment: number;
}

export interface CartItem {
  key: string;
  product: PosProduct;
  quantity: number;
  modifiers: SelectedModifier[];
  unitPrice: number;
}

export interface TransactionItem {
  id: number;
  product_id: number;
  product_name: string;
  sku: string;
  quantity: number;
  unit_price: number;
  modifiers?: SelectedModifier[];
  modifier_price_adjustment?: number;
  subtotal: number;
}

export interface PosTransaction {
  id: number;
  uuid: string;
  transaction_number: string;
  outlet?: { id: number; name: string; code: string };
  cashier?: { id: number; name: string };
  order_type: string;
  status: string;
  subtotal: number;
  discount_total: number;
  tax_total: number;
  service_charge: number;
  grand_total: number;
  notes?: string | null;
  items?: TransactionItem[];
  payments?: {
    id: number;
    amount: number;
    reference_number?: string | null;
    payment_method?: { id: number; name: string; code: string; type: string };
  }[];
  completed_at?: string;
  created_at?: string;
  wifi?: { ssid: string; password: string } | null;
}

export interface CreateTransactionPayload {
  outlet_id: number;
  shift_id?: number;
  member_id?: number;
  points_redeem?: number;
  order_type?: string;
  items: {
    product_id: number;
    quantity: number;
    modifiers?: number[];
  }[];
  payments: {
    payment_method_id: number;
    amount: number;
    reference_number?: string;
  }[];
  notes?: string;
}

export function buildCartItemKey(
  productId: number,
  modifiers: SelectedModifier[]
): string {
  const modifierIds = modifiers
    .map((m) => m.modifier_id)
    .sort((a, b) => a - b)
    .join(",");
  return `${productId}:${modifierIds}`;
}

export function calcUnitPrice(
  basePrice: number,
  modifiers: SelectedModifier[]
): number {
  const adjustment = modifiers.reduce((sum, m) => sum + m.price_adjustment, 0);
  return basePrice + adjustment;
}