export interface OrderItem {
  id: number;
  product_id: number;
  product_name: string;
  quantity: number;
  unit_price: number;
  subtotal: number;
  notes?: string | null;
  status: string;
}

export interface Order {
  id: number;
  uuid: string;
  order_number: string;
  outlet?: { id: number; name: string; code: string };
  table?: { id: number; table_number: string; name?: string | null } | null;
  source: string;
  order_type: string;
  status: string;
  subtotal: number;
  notes?: string | null;
  items?: OrderItem[];
  created_at?: string;
  updated_at?: string;
}

export interface MenuProduct {
  id: number;
  name: string;
  category_id?: number | null;
  category_name?: string | null;
  base_price: number;
}

export interface MenuCategory {
  id: number;
  name: string;
}

export interface DigitalMenu {
  tenant: { name: string; slug: string; logo_url?: string | null };
  outlet: { id: number; name: string; slug: string; address?: string | null };
  settings: {
    theme_color: string;
    welcome_message: string;
    show_prices: boolean;
    allow_guest_order: boolean;
  };
  categories: MenuCategory[];
  products: MenuProduct[];
  table?: {
    id: number;
    table_number: string;
    name?: string | null;
    area?: string | null;
  };
}

export interface CartItem {
  product: MenuProduct;
  quantity: number;
  notes?: string;
}

export interface OrderTrack {
  uuid: string;
  order_number: string;
  status: string;
  subtotal: number;
  table?: { table_number: string; name?: string | null } | null;
  items: { product_name: string; quantity: number; status: string }[];
  created_at?: string;
  updated_at?: string;
}