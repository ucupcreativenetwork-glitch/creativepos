export interface Category {
  id: number;
  uuid: string;
  name: string;
  slug: string;
  is_active: boolean;
}

export type RawMaterialUnit = "gram" | "ml" | "pcs" | "liter";

export interface RawMaterial {
  id: number;
  name: string;
  unit: RawMaterialUnit;
  current_stock: number;
  min_stock: number;
  cost_per_unit: number;
  is_active: boolean;
  is_low_stock: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface ProductRecipeLine {
  id: number;
  product_id: number;
  raw_material_id: number;
  quantity_needed: number;
  unit: RawMaterialUnit;
  notes?: string | null;
  line_cost: number;
  raw_material?: {
    id: number;
    name: string;
    unit: RawMaterialUnit;
    cost_per_unit: number;
    current_stock: number;
  };
}

export interface ProductRecipeResponse {
  product_id: number;
  product_name: string;
  ingredients: ProductRecipeLine[];
  cogs: number;
}

export interface ProductRecipeIngredient {
  id?: number;
  raw_material_id: number;
  quantity_needed: number;
  unit?: RawMaterialUnit;
  notes?: string;
}

export interface Product {
  id: number;
  uuid: string;
  name: string;
  image_url?: string | null;
  sku: string;
  barcode?: string | null;
  category?: { id: number; name: string; uuid?: string } | null;
  base_price: number;
  cost_price: number;
  min_stock: number;
  track_stock: boolean;
  is_active: boolean;
  is_available: boolean;
  show_in_pos: boolean;
  total_stock: number;
  stocks?: ProductStock[];
  recipe?: ProductRecipeLine[];
  cogs?: number;
}

export interface ProductStock {
  warehouse_id: number;
  warehouse?: { id: number; name: string; code: string } | null;
  quantity: number;
  reserved_quantity: number;
}

export interface Warehouse {
  id: number;
  name: string;
  code: string;
  outlet_id?: number | null;
}

export interface StockAlert {
  product: { id: number; name: string; sku: string; min_stock: number };
  warehouse: { id: number; name: string; code: string };
  quantity: number;
  deficit: number;
}

export interface StockMovement {
  id: number;
  type: string;
  quantity: number;
  before_quantity: number;
  after_quantity: number;
  notes?: string | null;
  product?: { id: number; name: string; sku: string };
  warehouse?: { id: number; name: string; code: string };
  created_by?: { id: number; name: string };
  created_at?: string;
}

export interface PaginatedMeta {
  current_page: number;
  per_page: number;
  total: number;
  last_page: number;
}

export interface ProductPayload {
  name: string;
  image_url?: string | null;
  sku: string;
  barcode?: string;
  category_id?: number | null;
  base_price: number;
  cost_price?: number;
  min_stock?: number;
  track_stock?: boolean;
  is_active?: boolean;
  is_available?: boolean;
  show_in_pos?: boolean;
  initial_stock?: number;
}

export interface CategoryPayload {
  name: string;
  is_active?: boolean;
}

export interface StockMovementPayload {
  product_id: number;
  warehouse_id: number;
  quantity: number;
  notes?: string;
}

export interface RawMaterialPayload {
  name: string;
  unit: RawMaterialUnit;
  current_stock?: number;
  min_stock?: number;
  cost_per_unit?: number;
  is_active?: boolean;
}

export interface RawMaterialStockPayload {
  quantity: number;
  notes?: string;
}